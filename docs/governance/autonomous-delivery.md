# Autonomous delivery

Bobi Watch separates code authorship, review, and merge eligibility.

## Roles

The first-stage Builder is the protected `Open bot-authored pull request` GitHub Actions workflow. Codex pushes a reviewed documentation candidate to a disposable `staging/*` branch, then sends an `open-bot-pull-request` repository event containing the exact reviewed source SHA. GitHub always runs repository-event workflows from the default branch. The workflow requires the fetched staging ref to match that SHA, rebuilds one commit on current `develop`, pushes it as `github-actions[bot]`, opens the pull request, and deletes the staging branch only if it still points to the reviewed source SHA.

The bootstrap Builder accepts at most 25 non-binary, non-executable Markdown files of at most 256 KiB each under unprotected `docs/**` paths, and it only creates `docs/*` branches. It rejects protected paths, symlinks, submodules, stale bases, existing target branches, source-SHA mismatches, unsupported branch names, and workflow re-runs; a retry requires a fresh dispatch against the current default branch. It rechecks `develop` immediately before creating the target branch, and strict branch protection blocks merge if the base advances afterward. Its job receives `contents: write`, `pull-requests: write`, and `checks: write`. It receives no administration, secret, deployment, member, or bypass permission. The workflow runs no code from the staging branch. It uses the policy script copied from the default-branch checkout before reconstructing the candidate tree.

Codex reviews routine product changes through the `FedeSack` GitHub identity. A separate review agent checks the exact head SHA before Codex submits the formal GitHub approval. The GitHub record proves which account approved the pull request. It does not prove that Federico personally reviewed it.

A dedicated Reviewer App may replace that identity after a test proves that GitHub counts its approval toward the branch rule. Until that test passes, protected repository changes remain frozen after the initial bootstrap. The `CODEOWNERS` file routes protected-path review to Federico.

GitHub merges only after required checks, one non-author approval, and resolved conversations. Auto-merge may finish an eligible documentation pull request after the live canary proves the complete path. No actor uses an administrator bypass for routine delivery.

## Protected changes

Changes to `.github/**`, `SECURITY.md`, `CODEOWNERS`, `scripts/check-repository-policy.sh`, repository rules, App permissions, signing, releases, and secret configuration require Federico's explicit approval. They also require an author and reviewer with distinct GitHub identities. The first-stage Builder and `FedeSack` review flow does not make those changes autonomous.

Product branches cannot weaken protected controls as part of an unrelated change. If a protected change is necessary before the Reviewer App is ready, Federico chooses the author and the distinct reviewer for that pull request.

GitHub creates a short-lived `GITHUB_TOKEN` for each Builder run. The token is limited to this repository and the permissions declared in the protected workflow. Bobi Watch stores no private key or long-lived Builder token.

GitHub's repository setting couples permission for Actions to create pull requests with permission to submit approving reviews. Bobi Watch enables that setting only so this Builder can create pull requests. The Builder never submits a review; its workflow and script are protected changes, and an approval from the same bot identity would not satisfy the distinct-reviewer rule.

The repository policy uses `pull_request_target` with read-only contents permission and only accepts pull requests targeting `main` or `develop`. GitHub loads that workflow from the repository's default branch. During bootstrap it accepts only same-repository pull requests, checks out the candidate only as data with the current hardened `actions/checkout` release, and executes the canonical policy script from the exact `workflow_sha` on protected `main`; it never executes candidate code or policy from another base branch. GitHub may suppress this event when the Builder creates a pull request with `GITHUB_TOKEN`, so it is not the bot path's required check.

After reconstructing the exact candidate and running the copied protected policy, the Builder opens the pull request, verifies its base and head names and OIDs, and emits a completed `Builder repository policy` check on that exact target SHA. The base-branch policy independently rechecks the actual pull-request diff when GitHub emits that event. Both policies require one non-merge commit directly on the current base and repeat the documentation allowlist, protected-path rules, and symlink/submodule rejection.

The Builder check is a self-attested policy receipt, not independent CI. It is required only for pull requests targeting `develop`, and its source must be pinned to the GitHub Actions App in branch protection. Retargeting to `main` therefore cannot reuse it as a release gate; `main` requires a separate release policy before autonomous promotion. The separate reviewer and formal non-author GitHub approval remain mandatory. Branch rules use strict up-to-date checks, dismiss stale approvals, and require approval of the most recent reviewable push by someone other than that push's author.

## Pull request sequence

1. Codex prepares one documentation change, scans and reviews its exact tree before any remote push, publishes it to a current `staging/*` branch, and records that exact SHA. A staging push is already public disclosure.
2. The protected Builder requires that SHA, recreates the change on current `develop`, and opens a focused pull request as `github-actions[bot]`.
3. The protected Builder emits its self-attested policy receipt on the reconstructed head. The read-only base-branch policy also runs when GitHub emits the corresponding event.
4. A separate reviewer inspects the diff, findings, test output, and exact head SHA.
5. If review finds an issue, Codex closes the superseded pull request and uses a fresh staging and target branch. Reviews never carry to the replacement.
6. Codex approves the final head through `FedeSack`.
7. GitHub auto-merge completes the pull request when every rule passes.

Product source is outside this bootstrap Builder's allowlist. Autonomous product delivery remains disabled until exact-head product CI is implemented and independently reviewed.

## One-time bootstrap exception

The pull requests that install these controls on `develop` and then `main` predate the Builder and branch rules. They are authored through `FedeSack`, so that same identity cannot record a distinct GitHub approval. They may be merged only once after independent review of the exact commit, passing local and hosted checks, and Federico's explicit authorization of the workflow permissions and repository-wide Actions setting. This exception ends before the live bot-authored canary and does not apply to later protected changes.

A passing secret scan detects known patterns. It does not certify that a file, commit, or history is suitable for publication.
