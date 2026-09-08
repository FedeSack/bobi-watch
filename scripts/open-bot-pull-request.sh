#!/usr/bin/env bash
set -euo pipefail

: "${BASE_BRANCH:?BASE_BRANCH is required}"
: "${SOURCE_BRANCH:?SOURCE_BRANCH is required}"
: "${TARGET_BRANCH:?TARGET_BRANCH is required}"
: "${PR_TITLE:?PR_TITLE is required}"
: "${PR_BODY:?PR_BODY is required}"
: "${EXPECTED_SOURCE_SHA:?EXPECTED_SOURCE_SHA is required}"

if [[ ! "$EXPECTED_SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  printf 'expected source SHA must be 40 lowercase hexadecimal characters\n' >&2
  exit 1
fi

dry_run=${BOBI_BUILDER_DRY_RUN:-0}
if [[ "$dry_run" != "1" ]]; then
  : "${EXPECTED_ACTOR:?EXPECTED_ACTOR is required outside dry-run mode}"
  : "${EXPECTED_DEFAULT_REF:?EXPECTED_DEFAULT_REF is required outside dry-run mode}"
  : "${EXPECTED_REPOSITORY:?EXPECTED_REPOSITORY is required outside dry-run mode}"
  : "${EXPECTED_RUN_ATTEMPT:?EXPECTED_RUN_ATTEMPT is required outside dry-run mode}"
  : "${GITHUB_ACTOR:?GITHUB_ACTOR is required outside dry-run mode}"
  : "${GITHUB_EVENT_NAME:?GITHUB_EVENT_NAME is required outside dry-run mode}"
  : "${GITHUB_REF:?GITHUB_REF is required outside dry-run mode}"
  : "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required outside dry-run mode}"
  : "${GITHUB_RUN_ATTEMPT:?GITHUB_RUN_ATTEMPT is required outside dry-run mode}"
  : "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required outside dry-run mode}"
  : "${GITHUB_SERVER_URL:?GITHUB_SERVER_URL is required outside dry-run mode}"
  : "${GITHUB_SHA:?GITHUB_SHA is required outside dry-run mode}"
  : "${GITHUB_TRIGGERING_ACTOR:?GITHUB_TRIGGERING_ACTOR is required outside dry-run mode}"
  : "${RUNNER_TEMP:?RUNNER_TEMP is required outside dry-run mode}"

  if [[ "$GITHUB_EVENT_NAME" != "repository_dispatch" ]]; then
    printf 'builder requires repository_dispatch: %s\n' "$GITHUB_EVENT_NAME" >&2
    exit 1
  fi
  if [[ "$GITHUB_ACTOR" != "$EXPECTED_ACTOR" ]]; then
    printf 'builder actor is not allowed: %s\n' "$GITHUB_ACTOR" >&2
    exit 1
  fi
  if [[ "$GITHUB_TRIGGERING_ACTOR" != "$EXPECTED_ACTOR" ]]; then
    printf 'builder triggering actor is not allowed: %s\n' "$GITHUB_TRIGGERING_ACTOR" >&2
    exit 1
  fi
  if [[ "$GITHUB_REF" != "$EXPECTED_DEFAULT_REF" ]]; then
    printf 'builder did not start from the expected default ref: %s\n' "$GITHUB_REF" >&2
    exit 1
  fi
  if [[ "$GITHUB_REPOSITORY" != "$EXPECTED_REPOSITORY" ]]; then
    printf 'builder repository is not allowed: %s\n' "$GITHUB_REPOSITORY" >&2
    exit 1
  fi
  if [[ "$GITHUB_RUN_ATTEMPT" != "$EXPECTED_RUN_ATTEMPT" ]]; then
    printf 'builder runs cannot be re-run; send a fresh dispatch\n' >&2
    exit 1
  fi
  if [[ "$(git rev-parse HEAD)" != "$GITHUB_SHA" ]]; then
    printf 'builder checkout does not match the event SHA\n' >&2
    exit 1
  fi
fi

if [[ "$BASE_BRANCH" != "develop" ]]; then
  printf 'the routine builder only targets develop: %s\n' "$BASE_BRANCH" >&2
  exit 1
fi

git check-ref-format --branch "$SOURCE_BRANCH" >/dev/null
git check-ref-format --branch "$TARGET_BRANCH" >/dev/null

case "$SOURCE_BRANCH" in
  staging/*) ;;
  *)
    printf 'source branch must use staging/<slug>: %s\n' "$SOURCE_BRANCH" >&2
    exit 1
    ;;
esac

case "$TARGET_BRANCH" in
  docs/*) ;;
  *)
    printf 'the bootstrap builder only creates docs branches: %s\n' "$TARGET_BRANCH" >&2
    exit 1
    ;;
esac

if [[ "$SOURCE_BRANCH" == "$TARGET_BRANCH" ]]; then
  printf 'source and target branches must differ\n' >&2
  exit 1
fi

title_pattern='^docs(\([a-z0-9][a-z0-9._/-]*\))?!?: .+'
if [[ ! "$PR_TITLE" =~ $title_pattern ]]; then
  printf 'bootstrap pull request title must use the docs Conventional Commit type: %s\n' "$PR_TITLE" >&2
  exit 1
fi

policy_script=$(mktemp)
cp scripts/check-repository-policy.sh "$policy_script"
trap 'rm -f "$policy_script"' EXIT

git fetch --no-tags origin \
  "+refs/heads/$BASE_BRANCH:refs/remotes/origin/$BASE_BRANCH" \
  "+refs/heads/$SOURCE_BRANCH:refs/remotes/origin/$SOURCE_BRANCH"

base_sha=$(git rev-parse --verify "refs/remotes/origin/$BASE_BRANCH^{commit}")
source_sha=$(git rev-parse --verify "refs/remotes/origin/$SOURCE_BRANCH^{commit}")
merge_base=$(git merge-base "$base_sha" "$source_sha")

if [[ "$source_sha" != "$EXPECTED_SOURCE_SHA" ]]; then
  printf 'staging branch does not match the reviewed source SHA\n' >&2
  exit 1
fi

if [[ "$merge_base" != "$base_sha" ]]; then
  printf 'source branch is not based on current %s\n' "$BASE_BRANCH" >&2
  exit 1
fi

set +e
git ls-remote --exit-code --heads origin "refs/heads/$TARGET_BRANCH" >/dev/null 2>&1
target_status=$?
set -e
if [[ $target_status -eq 0 ]]; then
  printf 'target branch already exists: %s\n' "$TARGET_BRANCH" >&2
  exit 1
fi
if [[ $target_status -ne 2 ]]; then
  printf 'could not verify whether target branch exists: %s\n' "$TARGET_BRANCH" >&2
  exit 1
fi

mapfile -d '' changed_paths < <(git diff --no-renames --name-only -z "$base_sha..$source_sha")
if [[ ${#changed_paths[@]} -eq 0 ]]; then
  printf 'source branch has no changes relative to %s\n' "$BASE_BRANCH" >&2
  exit 1
fi
if [[ ${#changed_paths[@]} -gt 25 ]]; then
  printf 'bootstrap source exceeds the 25-file limit\n' >&2
  exit 1
fi

for path in "${changed_paths[@]}"; do
  case "$path" in
    .github/*|.agents/*|*/.agents/*|.codex/*|*/.codex/*|.gitattributes|*/.gitattributes|.gitignore|*/.gitignore|.gitmodules|*/.gitmodules|AGENTS.md|*/AGENTS.md|SECURITY.md|*/SECURITY.md|CONTRIBUTING.md|*/CONTRIBUTING.md|CODE_OF_CONDUCT.md|*/CODE_OF_CONDUCT.md|GOVERNANCE.md|*/GOVERNANCE.md|LICENSE*|*/LICENSE*|NOTICE*|*/NOTICE*|THIRD_PARTY_NOTICES.md|*/THIRD_PARTY_NOTICES.md|docs/governance/*|scripts/check-repository-policy.sh|scripts/open-bot-pull-request.sh)
      printf 'routine builder cannot change protected path: %s\n' "$path" >&2
      exit 1
      ;;
  esac

  case "$path" in
    docs/*.md) ;;
    *)
      printf 'bootstrap builder only accepts Markdown documentation paths: %s\n' "$path" >&2
      exit 1
      ;;
  esac

  mode=$(git ls-tree "$source_sha" -- "$path" | awk 'NR == 1 { print $1 }')
  if [[ "$mode" == "120000" || "$mode" == "160000" ]]; then
    printf 'routine builder rejects symlinks and submodules: %s\n' "$path" >&2
    exit 1
  fi
  if [[ -n "$mode" && "$mode" != "100644" ]]; then
    printf 'bootstrap builder only accepts non-executable regular files: %s\n' "$path" >&2
    exit 1
  fi
  if [[ -n "$mode" ]]; then
    blob_size=$(git cat-file -s "$source_sha:$path")
    if [[ "$blob_size" -gt 262144 ]]; then
      printf 'bootstrap builder file exceeds 256 KiB: %s\n' "$path" >&2
      exit 1
    fi
    IFS=$'\t' read -r added_lines deleted_lines _ < <(
      LC_ALL=C git diff --no-renames --numstat "$base_sha..$source_sha" -- "$path"
    )
    if [[ "$added_lines" == "-" || "$deleted_lines" == "-" ]]; then
      printf 'bootstrap builder rejects binary content: %s\n' "$path" >&2
      exit 1
    fi
  fi
done

git switch --detach "$base_sha"
git switch -c "$TARGET_BRANCH"
git diff --binary "$base_sha" "$source_sha" | git apply --binary --index
git diff --cached --check

git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
git commit -m "$PR_TITLE"

target_sha=$(git rev-parse HEAD)
parent_sha=$(git rev-parse HEAD^)
if [[ "$parent_sha" != "$base_sha" ]]; then
  printf 'builder commit does not have the expected parent\n' >&2
  exit 1
fi
if ! git diff --quiet "$source_sha" "$target_sha" --; then
  printf 'builder tree does not match the staged source tree\n' >&2
  exit 1
fi

POLICY_EVENT_NAME=pull_request \
PR_BASE_REF="$BASE_BRANCH" \
PR_BASE_SHA="$base_sha" \
PR_HEAD_REF="$TARGET_BRANCH" \
PR_HEAD_SHA="$target_sha" \
PR_TITLE="$PR_TITLE" \
  bash "$policy_script"

if [[ "$dry_run" == "1" ]]; then
  printf 'dry-run target: %s\n' "$target_sha"
  printf 'dry-run source: %s\n' "$source_sha"
  printf 'dry-run base: %s\n' "$base_sha"
  exit 0
fi

: "${GH_TOKEN:?GH_TOKEN is required outside dry-run mode}"

remote_base_sha=$(git ls-remote --heads origin "refs/heads/$BASE_BRANCH" | awk 'NR == 1 { print $1 }')
if [[ "$remote_base_sha" != "$base_sha" ]]; then
  printf 'base branch advanced before target creation\n' >&2
  exit 1
fi

git push \
  --force-with-lease="refs/heads/$TARGET_BRANCH:" \
  origin \
  "HEAD:refs/heads/$TARGET_BRANCH"

body_file="$RUNNER_TEMP/bobi-watch-pr-body.md"
printf '%s\n\n' "$PR_BODY" > "$body_file"
printf '## Builder receipt\n\n' >> "$body_file"
printf -- '- Base `%s`: `%s`\n' "$BASE_BRANCH" "$base_sha" >> "$body_file"
printf -- '- Staging source `%s`: `%s`\n' "$SOURCE_BRANCH" "$source_sha" >> "$body_file"
printf -- '- Bot-authored head `%s`: `%s`\n' "$TARGET_BRANCH" "$target_sha" >> "$body_file"

pr_url=$(gh pr create \
  --repo "$GITHUB_REPOSITORY" \
  --base "$BASE_BRANCH" \
  --head "$TARGET_BRANCH" \
  --title "$PR_TITLE" \
  --body-file "$body_file")

IFS=$'\t' read -r observed_base observed_base_sha observed_head observed_head_sha < <(
  gh pr view "$pr_url" \
    --repo "$GITHUB_REPOSITORY" \
    --json baseRefName,baseRefOid,headRefName,headRefOid \
    --jq '[.baseRefName, .baseRefOid, .headRefName, .headRefOid] | @tsv'
)
if [[ "$observed_base" != "$BASE_BRANCH" || "$observed_base_sha" != "$base_sha" || "$observed_head" != "$TARGET_BRANCH" || "$observed_head_sha" != "$target_sha" ]]; then
  printf 'created pull request does not match the reconstructed target\n' >&2
  exit 1
fi

details_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
gh api \
  --method POST \
  "repos/$GITHUB_REPOSITORY/check-runs" \
  -f name='Builder repository policy' \
  -f head_sha="$target_sha" \
  -f status='completed' \
  -f conclusion='success' \
  -f details_url="$details_url" \
  -f 'output[title]=Protected bootstrap Builder policy passed' \
  -f 'output[summary]=The default-branch Builder validated the reviewed source SHA, documentation-only paths, branch direction, title, base commit, and reconstructed tree.' \
  >/dev/null

git push \
  --force-with-lease="refs/heads/$SOURCE_BRANCH:$source_sha" \
  origin \
  ":refs/heads/$SOURCE_BRANCH"
printf 'pull request: %s\n' "$pr_url"
