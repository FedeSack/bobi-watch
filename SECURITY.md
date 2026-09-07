# Security policy

## Report a vulnerability privately

Use [GitHub private vulnerability reporting](https://github.com/FedeSack/bobi-watch/security/advisories/new). Do not open a public issue for a suspected vulnerability.

Include the affected commit or version, the expected impact, reproduction steps, and any suggested mitigation. Remove credentials, personal data, session transcripts, and machine-specific values from the report.

## Supported versions

Bobi Watch has no supported release yet. Security reports about the repository bootstrap and planned architecture are still welcome.

## Security boundaries

The repository does not accept provider credentials, signing material, device secrets, session dumps, or private infrastructure configuration. Examples and tests use synthetic values.

Transport security will not grant Bobi authorization. The product design treats device identity, lifecycle state, replay protection, scoped capabilities, and user confirmation as separate controls.
