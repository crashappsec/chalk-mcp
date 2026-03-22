# Data Residency

As part of setup, the Chalk MCP server will ask you to choose your **desired data residency model**.

## Hosted

Data is stored by [Crash Override](https://crashoverride.com). You sign in
with a free account and reports hosted by [Crash Override](https://crashoverride.com/).

| Capability                                                                          | Supported |
| ----------------------------------------------------------------------------------- | --------- |
| Build reports                                                                       | Yes       |
| Provenance Chalk marks                                                              | Yes       |
| Extract / inspect images                                                            | Yes       |
| Query build history                                                                 | Yes       |
| CI/CD integration with your pipelines                                               | Yes       |
| [Exec reports](https://chalkproject.io/docs/use-cases/exec/) from deployed services | Yes       |
| [Heartbeat reports](https://chalkproject.io/docs/use-cases/heartbeat/)              | Yes       |

Best for: seeing the true power of Chalk in action, connecting your builds
to your services.

## Local

All data stays on your machine. Reports are written to a local volume
managed by Docker.

| Capability                                                                          | Supported |
| ----------------------------------------------------------------------------------- | --------- |
| Build reports                                                                       | Yes       |
| Provenance Chalk marks                                                              | Yes       |
| Extract / inspect images                                                            | Yes       |
| Query build history                                                                 | Yes       |
| CI/CD integration with your pipelines                                               | No        |
| [Exec reports](https://chalkproject.io/docs/use-cases/exec/) from deployed services | No        |
| [Heartbeat reports](https://chalkproject.io/docs/use-cases/heartbeat/)              | No        |

Best for: trying Chalk out locally or in air-gapped environments.
Note that, despite having data locally only, you can still configure
Chalk with custom sinks to send data to an S3 bucket that you control. See
the [official Chalk documentation on sinks](https://chalkproject.io/docs/configuration/#sinks).
