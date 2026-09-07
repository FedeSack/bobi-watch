# Contributing

Bobi Watch is in an early public bootstrap. Open an issue before a large change. Product source contributions remain closed until the repository has a license.

## Branches and pull requests

Create short-lived branches from `develop`:

- `feature/<slug>` for product behavior
- `fix/<slug>` for corrections
- `docs/<slug>` for documentation
- `test/<slug>` for test-only changes
- `refactor/<slug>` for behavior-preserving code changes
- `chore/<slug>` for repository maintenance

Release branches use `release/<version>` and target `main`. Urgent fixes use `hotfix/<slug>` and target `main`. A `main` to `develop` pull request returns release or hotfix changes to development.

Use a Conventional Commit title such as `docs(repo): explain the public history`. Each pull request must state its scope, risks, checks, and missing validation.

Do not push directly to `main` or `develop`. GitHub merges a pull request only after required checks, a distinct-author approval, and resolved review conversations. Never use an administrator bypass to merge routine work.

## Public content rules

Do not commit credentials, tokens, signing files, private hostnames, local home paths, personal session data, employer code, or third-party material without redistribution rights. A secret scan is necessary, but it does not prove that content is suitable for publication.

Do not copy source or design from an older Watch project. Cite primary sources for time-sensitive platform claims.

## Validation

Run `bash scripts/check-repository-policy.sh` before opening a pull request. Add focused tests with product changes. A Linux Swift test does not prove watchOS SDK, Simulator, hardware, signing, or distribution behavior.
