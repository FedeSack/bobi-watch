# Independent review canary

This pull request tests the repository's author and reviewer separation before branch protection becomes mandatory.

The canary passes only when GitHub records these results on the same head commit:

- the repository policy check succeeds;
- the pull request author and approving reviewer are different identities;
- GitHub records the review state as `APPROVED`;
- the merge uses no administrator bypass.

This receipt does not grant repository permissions or certify future pull requests.
