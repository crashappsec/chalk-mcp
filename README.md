> [!WARNING]
> **Alpha Preview** — This server is experimental and provided as an early preview of the upcoming, officially supported release which will be getting published in this repo! Stay tuned!
> The chalk MCP server aims to make onboarding easier for new [Chalk](https://github.com/crashappsec/chalk) users and act as a playground for you to try Chalk either locally or in your CI/CD.
> For a thorough, authoritative Chalk documentation visit [chalkproject.io](https://chalkproject.io/).

# Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/crashappsec/chalk-mcp/main/setup.sh | bash
```

To force overwrite ALL previous local state use:

```bash
curl -fsSL https://raw.githubusercontent.com/crashappsec/chalk-mcp/main/setup.sh | bash -s -- --force
```

> Requires [Docker Desktop 4.65+](https://docs.docker.com/desktop/setup/install/) with MCP Toolkit.
> Verify with: `docker mcp version`

# Quickstart Guides

| Guide                                            | Description                                           |
| ------------------------------------------------ | ----------------------------------------------------- |
| [Build an Image](docs/quickstart-build-image.md) | Build and sign a container image with full provenance |
| [CI/CD Integration](docs/quickstart-cicd.md)     | Add Chalk to your CI/CD pipelines                     |


# About

The Chalk MCP server helps your AI agent of choice setup Chalk to build, sign, and inspect container images
with full provenance — no manual tooling required. It is using the [Docker MCP Toolkit](https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/)
to allow you to spin up an MCP server in a dedicated docker container on your local dev machine, experiment with Chalk,
and make it available to any client of your choice (e.g., Claude Code, Codex) you have connected to Docker.

To connect a client to Docker's MCP server, open Docker Desktop and select `Clients > Connect`:

<img width="1251" height="707" alt="Screenshot 2026-03-22 at 10 13 17 PM" src="https://github.com/user-attachments/assets/60d225a9-2786-47aa-8f1d-7984d3d660d7" />

## Chalk

[Chalk](https://github.com/crashappsec/chalk) adds software supply-chain traceability to your AI coding agent.
In short, it allows you to embed metadata into artifacts such as docker images, binaries, OCI artifacts and more, in a tamper-proof fashion,
and track said metadata across the artifact lifecycle. For instance, you can build a docker image with chalk, then track its provenance and execution
as this image is being deployed and used across different services:

<img width="1209" height="487" alt="Screenshot 2026-03-22 at 9 54 42 PM" src="https://github.com/user-attachments/assets/30c68160-c379-41eb-bc6d-6c00bee84ce4" />

For more information on the Chalk project see [chalkproject.io](https://chalkproject.io/).

## Data residency

Chalk MCP supports [hosted and local](docs/data-residency.md) data storage models.
