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
curl -fsSL https://raw.githubusercontent.com/crashappsec/chalk-mcp/main/setup.sh | bash
```

The installer pulls the server image, registers it with Docker MCP Toolkit,
and connects it to your chosen client (Claude Code, Cursor, VS Code, etc.).

Restart your AI coding agent after installation. You can verify the server
is available by checking your MCP tools list — you should see Chalk tools
like `crash_override_chalk`.

## 2. Clone the demo project

```bash
git clone https://github.com/crashoverride-chalk-mcp-demo/bare.git
cd bare
```

## 3. Build an image with Chalk

Open your AI coding agent in the `bare` directory and ask it:

> **"Can you build this image using Chalk?"**

During this process you'll choose a [data residency model](data-residency.md). In the following
we are showing you a sample workflow using [Claude Code](https://code.claude.com/docs/en/overview) - the actual set of prompts and steps
will vary based on your AI agent of choice, the exact model etc.

The agent will walk you through:

- Choosing a [data residency model](data-residency.md) (hosted or local)
- Accepting the Terms of Service (hosted mode)
- Completing SSO login via a browser link (hosted mode)
- Resolving your organization and workspace

<img width="822" height="358" alt="Screenshot 2026-03-22 at 9 31 08 PM" src="https://github.com/user-attachments/assets/81d03274-43c8-422b-ae0e-e463c03b9bec" />

Notice that the client will ask you for permission for the tool invocation. Clicking `Yes` will re-prompt again for permission in the next stage:
<img width="847" height="331" alt="Screenshot 2026-03-22 at 9 31 56 PM" src="https://github.com/user-attachments/assets/44d5d9a7-ea57-40fc-b739-1a84f07aa650" />

For the next invocations, we allow all uses of the tool for expediency and we get a prompt to accept the [Crash Override Terms of Service](https://crashoverride.run/terms-of-service) a link for performing SSO via Auth0:

<img width="479" height="102" alt="Screenshot 2026-03-22 at 9 32 11 PM" src="https://github.com/user-attachments/assets/c7b08f94-326d-49d3-9444-dbd7552695cc" />

<img width="1149" height="347" alt="Screenshot 2026-03-22 at 9 32 29 PM" src="https://github.com/user-attachments/assets/738cf9d2-f1cd-484a-a36a-edb11e9df6c0" />

After you complete your login you must select "Accept" or notify your client that log in was successful (some clients might automatically poll and this part will be automatic)

<img width="441" height="64" alt="Screenshot 2026-03-22 at 9 32 43 PM" src="https://github.com/user-attachments/assets/3a80e16c-300e-46d2-8f50-eb4b3b9148f9" />

Subsequently the build should just proceed and you should get a message that the image was successfully chalked:

<img width="1510" height="231" alt="Screenshot 2026-03-22 at 9 36 02 PM" src="https://github.com/user-attachments/assets/5f18960d-be4c-4dad-a889-c3247d3fcba0" />

## 4. Inspect the chalked image

Ask your AI agent about any of the chalk KEYs or other information. For instance

> **"what is the chalk METADATA_ID for this image?"**

<img width="1493" height="424" alt="Screenshot 2026-03-22 at 9 36 16 PM" src="https://github.com/user-attachments/assets/f89b16d6-74ee-4368-b26a-c3097c829994" />

You can also verify wrapping directly — a chalked image uses `/chalk exec --`
as its entrypoint, which transparently instruments runtime execution.

## 5. Explore further

You can query on any Chalk report field, inspect reports, etc.
In hosted mode you can ask which services a build was deployed to, in which regions, and more.

> **"Using the Chalk MCP server, tell me about my builds"**

Notice that clients might make mistakes when running SQL queries but should succeed in collecting data on their own:

<img width="1496" height="541" alt="Screenshot 2026-03-22 at 9 36 38 PM" src="https://github.com/user-attachments/assets/3ea9ed41-60d5-4c3f-bfda-b25374f535bb" />
