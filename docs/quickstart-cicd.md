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

For GitHub repositories you will also need:

- Org or repo admin access (to install the GitHub App)

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

### GitHub Actions

Below is a sample screenshot using Claude Code on a GitHub repository:

<img width="1498" height="583" alt="Screenshot 2026-03-22 at 10 29 20 PM" src="https://github.com/user-attachments/assets/c6453fbf-555d-462d-a65b-6f2875a0c0e3" />

The agent will:

### **Generate an install link** 

for the [Crash Override GitHub App](https://github.com/apps/crash-override) on your organization. 
Follow the link to authorize it and select the repositories you want to instrument.

First pick the appopriate org from the presented drop down menu

<img width="568" height="243" alt="Screenshot 2026-03-22 at 10 29 47 PM" src="https://github.com/user-attachments/assets/e8fd5f6f-2b47-436a-8a69-ca0f999aeead" />

then authorize the app for your org (not individual repositories ideally, so that you can expand should you wish to)

<img width="621" height="783" alt="Screenshot 2026-03-22 at 10 29 54 PM" src="https://github.com/user-attachments/assets/e005cb94-a2d9-4929-a959-7f4f12a4df3b" />

then you should see that the application was successfully installed:

<img width="637" height="399" alt="Screenshot 2026-03-22 at 10 30 02 PM" src="https://github.com/user-attachments/assets/0b97e885-5dbd-4f3d-8c45-822bc2b974f3" />


Once the GitHub App is installed it should be visible under your org's `/settings/installations`:
<img width="958" height="317" alt="Screenshot 2026-03-22 at 10 14 47 PM" src="https://github.com/user-attachments/assets/da70e110-2cc3-4673-9c19-d21bdea09c7e" />

2. The agent should then proceed to **Add the [`setup-chalk-action`](https://github.com/crashappsec/setup-chalk-action)**
   step to your workflow. The app configures the action ref, OIDC
   authentication, and Chalk profile automatically — no manual YAML
   editing is required beyond what the agent proposes, which should be similar to the snippet below:

```yaml
- name: Setup Chalk
  uses: crashappsec/setup-chalk-action@main
  with:
    connect: true
```

This installs Chalk into the runner and connects it to the
Crash Override platform so that build reports, provenance, and
deployment telemetry are captured for every CI build.

Note that **connect: true** is **essential** for sending data to Crash Override. If its missing the agent did a bad job at generating the right snippet for GitHub.

<img width="619" height="302" alt="Screenshot 2026-03-22 at 10 31 28 PM" src="https://github.com/user-attachments/assets/0f9737e7-f21f-45db-bd6f-28bdfb92ebc7" />

## 3. Trigger a build

Commit the workflow changes and push:

```bash
git add .
git commit -m "Add Chalk to CI/CD"
git push
```

Once the pipeline runs you should see Chalk output in your build logs
confirming it is active. Chalk wraps your Docker images with provenance
marks and records build data automatically.

<img width="951" height="708" alt="Screenshot 2026-03-22 at 10 38 18 PM" src="https://github.com/user-attachments/assets/d3a9d0e9-23e6-464d-bd6b-aba2b08605fc" />

> [!TIP]
> You can trigger a debug build to see detailed Chalk execution logs, by selecting `Enable debug logging` for github actions:

<img width="620" height="68" alt="Screenshot 2026-03-22 at 10 38 47 PM" src="https://github.com/user-attachments/assets/d2b65215-6e37-40c6-8078-ad93153aa521" />

## 4. Query your build data

A couple of minutes after the build completes, your build data will be
available through the MCP interface. Ask your AI agent:

> **"Using the Chalk MCP server, tell me about my builds"**

The agent will query and summarize your build history — repos, authors,
timestamps, success rates, and artifact provenance.
