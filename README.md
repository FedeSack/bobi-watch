# Bobi Watch

Bobi Watch is a standalone project for supervising coding-agent sessions from an independent Apple Watch app. A self-hosted Bridge will run on the user's development machine. The Watch will reach that Bridge across networks without requiring an iPhone companion app.

The product design focuses on short status updates, explicit approvals, and concise instructions. The planned protocol does not expose a general remote shell. Device identity, revocation, replay protection, least privilege, and an audit trail are design requirements.

## Repository status

This repository currently contains the public governance bootstrap. Watch, Bridge, and protocol source will arrive through reviewed pull requests after a separate content and license audit. No production service, signed app, TestFlight build, or public release exists yet.

The public history starts with this audited seed. Earlier working material was excluded during publication review.

## Planned layout

```text
apps/
  watch/       Independent watchOS client
  bridge/      Self-hosted machine service
packages/
  protocol/    Shared messages, pairing, lifecycle, and compatibility rules
docs/          Architecture, security, product, and decision records
scripts/       Reproducible repository checks
```

Pairing belongs to the shared protocol and both endpoint implementations. It is not a separate product repository.

Read [the repository topology](docs/architecture/repository-topology.md), [the delivery rules](docs/governance/autonomous-delivery.md), and [the security policy](SECURITY.md) before contributing.

## License status

No product source has been published yet. A `LICENSE` file will be added before product source is accepted. Until then, do not assume permission to copy, modify, or redistribute this repository.
