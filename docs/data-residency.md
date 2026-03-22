# Data Residency

As part of setup, the Chalk MCP server will ask you to choose your **desired data residency model**.

## Hosted

Data is stored by [Crash Override](https://crashoverride.com). You sign in
with a free account and reports are sent to the Crash Override platform.

| Capability                                                                          | Supported |
| ----------------------------------------------------------------------------------- | --------- |
| Build reports                                                                       | Yes       |
| Provenance chalk marks                                                              | Yes       |
| Extract / inspect images                                                            | Yes       |
| Query build history                                                                 | Yes       |
| CI/CD integration with your pipelines                                               | Yes       |
| [Exec reports](https://chalkproject.io/docs/use-cases/exec/) from deployed services | Yes       |
| [Heartbeat reports](https://chalkproject.io/docs/use-cases/heartbeat/)              | Yes       |

[Exec reports](https://chalkproject.io/docs/use-cases/exec/) are sent automatically when a chalked container runs in
production, giving you visibility into what was deployed, where, and when.
[Heartbeat reports](https://chalkproject.io/docs/use-cases/heartbeat/) provide ongoing liveness signals from running services.

Best for: seeing the true power of chalk in action, connecting your builds
to your services.

## Local

All data stays on your machine. Reports are written to a local volume
managed by Docker.

| Capability                                                                          | Supported |
| ----------------------------------------------------------------------------------- | --------- |
| Build reports                                                                       | Yes       |
| Provenance chalk marks                                                              | Yes       |
| Extract / inspect images                                                            | Yes       |
| Query build history                                                                 | Yes       |
| CI/CD integration with your pipelines                                               | No        |
| [Exec reports](https://chalkproject.io/docs/use-cases/exec/) from deployed services | No        |
| [Heartbeat reports](https://chalkproject.io/docs/use-cases/heartbeat/)              | No        |

Best for: trying Chalk out locally or in air-gapped environments.
Note that despite having data locally only, you can still configure
Chalk with custom sinks to send data to an S3 bucket that you control. See
the [official Chalk documentation on sinks](https://chalkproject.io/docs/configuration/#sinks).
