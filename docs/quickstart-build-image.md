# Quickstart: Build an Image

Build and sign a container image with full provenance using Chalk MCP.

## Prerequisites

| Requirement                                        | Version     | Install                                                                  |
| -------------------------------------------------- | ----------- | ------------------------------------------------------------------------ |
| [Docker Desktop](https://docs.docker.com/desktop/) | **4.65.0+** | [Install Docker Desktop](https://docs.docker.com/desktop/setup/install/) |
| [curl](https://curl.se/)                           | any         | [Install curl](https://curl.se/download.html)                            |
| [Git](https://git-scm.com/)                        | any         | [Install Git](https://git-scm.com/downloads)                             |

> Docker Desktop 4.65+ ships with the MCP Toolkit built in.
> Verify with: `docker mcp version`

## 1. Install the Chalk MCP server

```bash
curl -fsSL https://raw.githubusercontent.com/crashappsec/chalk-mcp/main/setup.sh | bash -s -- --force
```

The installer pulls the server image, registers it with Docker MCP Toolkit,
and connects it to your chosen client (Claude Code, Cursor, VS Code, etc.).

## 2. Clone the demo project

```bash
git clone https://github.com/crashoverride-chalk-mcp-demo/bare.git
cd bare
```

## 3. Build an image with Chalk

Open your AI coding agent in the `bare` directory and ask it:

> **"Can you build this image using Chalk?"**

During this process you'll choose a [data residency model](data-residency.md).

## 4. Query your data and see your report

Ask your AI agent:

> **"Can you extract the chalkmark from the built image?"**

## 5. Explore further

You can query on any chalk report field, inspect reports, etc.
In hosted mode you can ask which services a build was deployed to, in which regions, and more.
