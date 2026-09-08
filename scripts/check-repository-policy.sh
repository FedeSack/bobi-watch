#!/usr/bin/env bash
set -euo pipefail

required_files=(
  README.md
  SECURITY.md
  CONTRIBUTING.md
  .github/CODEOWNERS
  .github/pull_request_template.md
  .github/workflows/open-bot-pull-request.yml
  .github/workflows/repository-policy.yml
  docs/governance/autonomous-delivery.md
  scripts/open-bot-pull-request.sh
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$path" || -L "$path" || ! -s "$path" ]]; then
    printf 'required public file must be a non-empty regular file: %s\n' "$path" >&2
    exit 1
  fi
done

event_name=${POLICY_EVENT_NAME:-${GITHUB_EVENT_NAME:-}}
if [[ "$event_name" != "pull_request" ]]; then
  exit 0
fi

title=${PR_TITLE:-}
base=${PR_BASE_REF:-}
head=${PR_HEAD_REF:-}
base_sha=${PR_BASE_SHA:-}
head_sha=${PR_HEAD_SHA:-}
title_pattern='^(feat|fix|docs|test|refactor|perf|build|ci|chore|revert)(\([a-z0-9][a-z0-9._/-]*\))?!?: .+'

if [[ ! "$title" =~ $title_pattern ]]; then
  printf 'pull request title must use Conventional Commits: %s\n' "$title" >&2
  exit 1
fi

case "$base:$head" in
  develop:feature/*|develop:fix/*|develop:docs/*|develop:test/*|develop:refactor/*|develop:chore/*|develop:dependabot/*)
    ;;
  main:release/*|main:hotfix/*|develop:main)
    ;;
  *)
    printf 'unsupported pull request direction: %s -> %s\n' "$head" "$base" >&2
    exit 1
    ;;
esac

if [[ ! "$base_sha" =~ ^[0-9a-f]{40}$ || ! "$head_sha" =~ ^[0-9a-f]{40}$ ]]; then
  printf 'pull request policy requires exact 40-character base and head SHAs\n' >&2
  exit 1
fi

resolved_base=$(git rev-parse --verify "$base_sha^{commit}")
resolved_head=$(git rev-parse --verify "$head_sha^{commit}")
checked_out_head=$(git rev-parse HEAD)
if [[ "$resolved_base" != "$base_sha" || "$resolved_head" != "$head_sha" || "$checked_out_head" != "$head_sha" ]]; then
  printf 'pull request checkout does not match the exact policy SHAs\n' >&2
  exit 1
fi

read -r commit_sha parent_sha extra_parent < <(git rev-list --parents -n 1 "$head_sha")
if [[ "$commit_sha" != "$head_sha" || "$parent_sha" != "$base_sha" || -n "${extra_parent:-}" ]]; then
  printf 'pull request head must be one non-merge commit directly on the current base\n' >&2
  exit 1
fi

mapfile -d '' changed_paths < <(git diff --no-renames --name-only -z "$base_sha..$head_sha")
if [[ ${#changed_paths[@]} -eq 0 ]]; then
  printf 'pull request has no changes relative to its base\n' >&2
  exit 1
fi
if [[ ${#changed_paths[@]} -gt 25 ]]; then
  printf 'bootstrap pull request exceeds the 25-file limit\n' >&2
  exit 1
fi

for path in "${changed_paths[@]}"; do
  case "$path" in
    .github/*|.agents/*|*/.agents/*|.codex/*|*/.codex/*|.gitattributes|*/.gitattributes|.gitignore|*/.gitignore|.gitmodules|*/.gitmodules|AGENTS.md|*/AGENTS.md|SECURITY.md|*/SECURITY.md|CONTRIBUTING.md|*/CONTRIBUTING.md|CODE_OF_CONDUCT.md|*/CODE_OF_CONDUCT.md|GOVERNANCE.md|*/GOVERNANCE.md|LICENSE*|*/LICENSE*|NOTICE*|*/NOTICE*|THIRD_PARTY_NOTICES.md|*/THIRD_PARTY_NOTICES.md|docs/governance/*|scripts/check-repository-policy.sh|scripts/open-bot-pull-request.sh)
      printf 'pull request cannot change protected path: %s\n' "$path" >&2
      exit 1
      ;;
  esac

  case "$path" in
    docs/*.md) ;;
    *)
      printf 'bootstrap pull request only accepts Markdown documentation paths: %s\n' "$path" >&2
      exit 1
      ;;
  esac

  mode=$(git ls-tree "$head_sha" -- "$path" | awk 'NR == 1 { print $1 }')
  if [[ "$mode" == "120000" || "$mode" == "160000" ]]; then
    printf 'bootstrap pull request rejects symlinks and submodules: %s\n' "$path" >&2
    exit 1
  fi
  if [[ -n "$mode" && "$mode" != "100644" ]]; then
    printf 'bootstrap pull request only accepts non-executable regular files: %s\n' "$path" >&2
    exit 1
  fi
  if [[ -n "$mode" ]]; then
    blob_size=$(git cat-file -s "$head_sha:$path")
    if [[ "$blob_size" -gt 262144 ]]; then
      printf 'bootstrap pull request file exceeds 256 KiB: %s\n' "$path" >&2
      exit 1
    fi
    IFS=$'\t' read -r added_lines deleted_lines _ < <(
      LC_ALL=C git diff --no-renames --numstat "$base_sha..$head_sha" -- "$path"
    )
    if [[ "$added_lines" == "-" || "$deleted_lines" == "-" ]]; then
      printf 'bootstrap pull request rejects binary content: %s\n' "$path" >&2
      exit 1
    fi
  fi
done
