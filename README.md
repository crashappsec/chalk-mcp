> [!WARNING]
> **Alpha Preview** — This server is experimental and provided as an early preview of the upcoming, officially supported release.
> It aims to make onboarding easier for new Chalk users.
> For a thorough, authoritative Chalk documentation visit [chalkproject.io](https://chalkproject.io/).

# Chalk MCP Server

[Chalk](https://github.com/crashappsec/chalk) Adds software supply-chain traceability to your AI coding agent.
The Chalk MCP server lets your agent build, sign, and inspect container images
with full provenance — no manual tooling required. It is using the [Docker MCP Toolkit](https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/)
to allow you to spin up an MCP server in a dedicated docker container on your local dev machine, experiment with Chalk,
and make it available to any client of your choice (e.g., Claude Code, Codex) you have connected to Docker.

To connect a client to Docker's MCP server, open Docker Desktop and select Clients > Connect:

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/crashappsec/chalk-mcp/main/setup.sh | bash
```

To force overwrite ALL previous local state use::w

```bash
curl -fsSL https://raw.githubusercontent.com/crashappsec/chalk-mcp/main/setup.sh | bash -s -- --force
```

> Requires [Docker Desktop 4.65+](https://docs.docker.com/desktop/setup/install/) with MCP Toolkit.
> Verify with: `docker mcp version`

## Quickstart Guides

| Guide                                            | Description                                           |
| ------------------------------------------------ | ----------------------------------------------------- |
| [Build an Image](docs/quickstart-build-image.md) | Build and sign a container image with full provenance |
| [CI/CD Integration](docs/quickstart-cicd.md)     | Add Chalk to your CI/CD pipelines                     |

## Data residency

Chalk MCP supports [hosted and local](docs/data-residency.md) data storage models.
