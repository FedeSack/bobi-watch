# Repository topology

Bobi Watch uses one public repository for the Watch app, the self-hosted Bridge, and their shared protocol.

A protocol change often affects both endpoints. Keeping those changes in one pull request makes compatibility tests and security review easier to follow. The monorepo does not imply one process, one credential store, or one release artifact.

Pairing is a protocol boundary, not a third deployable product. Its messages, lifecycle rules, and compatibility fixtures belong in `packages/protocol`. Watch and Bridge keep their platform-specific key storage and transport code in their own directories.

Watch and Bridge will build and release separately. Tags use `watch-vX.Y.Z`, `bridge-vX.Y.Z`, and `protocol-vX.Y.Z`. Each component release records the protocol versions that it accepts. A breaking wire change increments the protocol major version.

Split a component into another repository only when it has independent maintainers, access rules, or a release process that the monorepo cannot represent cleanly. A separate project chat is not a reason to split the source.
