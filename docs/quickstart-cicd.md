# Quickstart: CI/CD Integration

Add Chalk to your CI/CD pipelines so every build is automatically
signed, traced, and reported.

> [!NOTE]
> This guide requires **Hosted** mode. If you haven't set that up yet,
> follow the [Build an Image quickstart](quickstart-build-image.md) first
> and choose the hosted [data residency](data-residency.md) option.

## Prerequisites

| Requirement                                                           | Version     | Install                                                                  |
| --------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------ |
| [Docker Desktop](https://docs.docker.com/desktop/)                    | **4.65.0+** | [Install Docker Desktop](https://docs.docker.com/desktop/setup/install/) |
| A repository hosted on GitHub, GitLab, or similar                     |             |                                                                          |
| A container registry or deployment target (e.g. ECR, GCR, AWS Lambda) |             |                                                                          |

## 1. Clone your repository

Clone a repository that builds and pushes a container image to a registry
and/or deploys to a production service such as AWS Lambda.

```bash
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>
```

## 2. Ask your AI agent to configure Chalk for CI/CD

Open your AI coding agent in the repository and ask it:

> **"Configure Chalk for CI/CD in this repo"**

The agent will guide you through the necessary steps depending on your
CI/CD provider (GitHub Actions, GitLab CI, etc.).

## GitHub Actions

For GitHub-based repositories, the agent will add the
[`setup-chalk-action`](https://github.com/crashappsec/setup-chalk-action)
to your workflow:

```yaml
- name: Setup Chalk
  uses: crashappsec/setup-chalk-action@main
  with:
    connect: true
```

This step installs Chalk into the runner and connects it to the
Crash Override platform so that build reports, provenance, and
deployment telemetry are automatically captured for every CI build.

The agent will also generate a link to install the
[Crash Override GitHub App](https://github.com/apps/crash-override) on
your organization. Follow the link to authorize it.

## 3. Trigger a build

Commit the workflow changes and push:

```bash
git add .
git commit -m "Add Chalk to CI/CD"
git push
```

Once the pipeline runs you should see Chalk output in your build logs
confirming it is active.

## 4. Query your build data

A couple of minutes after the build completes, your build data will be
available through the MCP interface. Ask your AI agent:

> **"Show me the latest Chalk build reports"**

> [!TIP]
> You can trigger a debug build to see detailed Chalk execution logs.
> Ask your AI agent: **"Trigger a debug build with Chalk"**
