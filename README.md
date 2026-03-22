# Chalk MCP Server

> **Alpha Preview** — This server is experimental and provided as an early preview of the officially supported release.
> It aims to make onboarding easier for new Chalk users.
> For full authoritative Chalk documentation visit [chalkproject.io](https://chalkproject.io/).

Add software supply-chain traceability to your AI coding agent.
Chalk MCP lets your agent build, sign, and inspect container images
with full provenance — no manual tooling required.

## Quickstart

### Prerequisites

| Requirement                                        | Version     | Install                                                                  |
| -------------------------------------------------- | ----------- | ------------------------------------------------------------------------ |
| [Docker Desktop](https://docs.docker.com/desktop/) | **4.65.0+** | [Install Docker Desktop](https://docs.docker.com/desktop/setup/install/) |
| [curl](https://curl.se/)                           | any         | [Install curl](https://curl.se/download.html)                            |
| [Git](https://git-scm.com/)                        | any         | [Install Git](https://git-scm.com/downloads)                             |

> Docker Desktop 4.65+ ships with the MCP Toolkit built in.
> Verify with: `docker mcp version`

### 1. Install the Chalk MCP server

```bash
curl -fsSL https://raw.githubusercontent.com/crashappsec/chalk-mcp/main/setup.sh | bash -s -- --force
```

The installer pulls the server image, registers it with Docker MCP Toolkit,
and connects it to your chosen client (Claude Code, Cursor, VS Code, etc.).

### 2. Clone the demo project

```bash
git clone https://github.com/crashoverride-chalk-mcp-demo/bare.git
cd bare
```

### 3. Build with Chalk

Open your AI coding agent in the `bare` directory that you just cloned and ask it:

> **"Build this image using chalk"**

As part of this process, the chalk mcp server will ask you to choose your **desired data residency model**:

#### Hosted

Data is stored by [Crash Override](https://crashoverride.com). You sign in
with a free account and reports are sent to the Crash Override platform.

| Capability                            | Supported |
| ------------------------------------- | --------- |
| Build reports                         | Yes       |
| Provenance chalk marks                | Yes       |
| Extract / inspect images              | Yes       |
| Query build history                   | Yes       |
| CI/CD integration with your pipelines | Yes       |
| Exec reports from deployed services   | Yes       |
| Heartbeat reports                     | Yes       |

Exec reports are sent automatically when a chalked container runs in
production, giving you visibility into what was deployed, where, and when.
Heartbeat reports provide ongoing liveness signals from running services.

Best for: seeing the true power of chalk in action, connecting your builds
to your services.

#### Local

All data stays on your machine. Reports are written to a local volume
managed by Docker.

| Capability                            | Supported |
| ------------------------------------- | --------- |
| Build reports                         | Yes       |
| Provenance chalk marks                | Yes       |
| Extract / inspect images              | Yes       |
| Query build history                   | Yes       |
| CI/CD integration with your pipelines | No        |
| Exec reports from deployed services   | No        |
| Heartbeat reports                     | No        |

Best for: trying Chalk out locally on an air-gapped environments.
Note that despite having data locally only you can stil configure
Chalk with custom sinks to send data into an s3 bucket that you control. See
the [official chalk documentation for more information on how to send your data
to various destinations via sinks](https://chalkproject.io/docs/configuration/#sinks).

### 4. Query your data and see your report

### 5. Instrument more builds and repositories and ask higher-level questions around your services
