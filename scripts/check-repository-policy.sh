#!/usr/bin/env bash
set -euo pipefail

required_files=(
  README.md
  SECURITY.md
  CONTRIBUTING.md
  .github/CODEOWNERS
  .github/pull_request_template.md
  .github/workflows/repository-policy.yml
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$path" || -L "$path" || ! -s "$path" ]]; then
    printf 'required public file must be a non-empty regular file: %s\n' "$path" >&2
    exit 1
  fi
done

if [[ "${GITHUB_EVENT_NAME:-}" != "pull_request" ]]; then
  exit 0
fi

title=${PR_TITLE:-}
base=${PR_BASE_REF:-}
head=${PR_HEAD_REF:-}
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
