# Autonomous delivery

Bobi Watch separates code authorship, review, and merge eligibility.

## Roles

The Builder GitHub App creates branches, commits, and pull requests. It receives repository-scoped content and pull request permissions. It receives no administration, secret, deployment, member, bypass, or workflow permission.

During the first stage, Codex reviews routine product changes through the `FedeSack` GitHub identity. The reviewer checks the exact head SHA and submits a formal GitHub review. The GitHub record proves which account approved the pull request. It does not prove that Federico personally reviewed it.

A later Reviewer App may replace that identity after a test proves that GitHub counts its approval toward the branch rule. Until that test passes, protected repository changes remain frozen after the initial bootstrap. The `CODEOWNERS` file routes protected-path review to Federico, but the first branch rule does not require code-owner review.

GitHub merges only after required checks, one non-author approval, and resolved conversations. Auto-merge may finish an eligible pull request. No actor uses an administrator bypass for routine delivery.

## Protected changes

Changes to `.github/**`, `SECURITY.md`, `CODEOWNERS`, `scripts/check-repository-policy.sh`, repository rules, App permissions, signing, releases, and secret configuration require Federico's explicit approval. They also require an author and reviewer with distinct GitHub identities. The first-stage Builder and `FedeSack` review flow does not make those changes autonomous.

Product branches cannot weaken protected controls as part of an unrelated change. If a protected change is necessary before the Reviewer App is ready, Federico chooses the author and the distinct reviewer for that pull request.

The Builder uses installation tokens that expire after one hour. Each token is limited to this repository and the permissions required for the current operation. Private keys stay in the operating system keyring or another approved secret store. They never appear in Git, logs, prompts, or chat.

## Pull request sequence

1. The Builder starts from the current protected base and opens a focused pull request.
2. GitHub runs checks with read-only workflow permissions.
3. A reviewer inspects the diff, findings, test output, and exact head SHA.
4. The Builder fixes findings. A new commit dismisses the old approval.
5. The reviewer approves the final head.
6. GitHub auto-merge completes the pull request when every rule passes.

A passing secret scan detects known patterns. It does not certify that a file, commit, or history is suitable for publication.
