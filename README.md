> [!WARNING]
> **Alpha Preview** — This server is experimental and provided as an early preview of the officially supported release.
> It aims to make onboarding easier for new Chalk users.
> For full authoritative Chalk documentation visit [chalkproject.io](https://chalkproject.io/).

# Chalk MCP Server

Add software supply-chain traceability to your AI coding agent.
Chalk MCP lets your agent build, sign, and inspect container images
with full provenance — no manual tooling required.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/crashappsec/chalk-mcp/main/setup.sh | bash -s -- --force
```

> Requires [Docker Desktop 4.65+](https://docs.docker.com/desktop/setup/install/) with MCP Toolkit.
> Verify with: `docker mcp version`

## Quickstart guides

| Guide | Description |
| ----- | ----------- |
| [Build an Image](docs/quickstart-build-image.md) | Build and sign a container image with full provenance |
| [CI/CD Integration](docs/quickstart-cicd.md) | Add Chalk to your CI/CD pipelines _(coming soon)_ |

## Data residency

Chalk MCP supports [hosted and local](docs/data-residency.md) data storage models.
