[< Back to Navigation](../README.md)

# Environments

There are three permanent environments for NPQ, plus a review app for the life of each Pull Request:

| Environment | URL | Used by | Purpose | Deployment trigger | Azure space | Deployed commit |
| - | - | - | - | - | - | - |
| Production | https://register-national-professional-qualifications.education.gov.uk | Real users | Live system | Merge to `main` | production | [View](https://register-national-professional-qualifications.education.gov.uk/healthcheck.json) |
| Sandbox | https://npq-registration-sandbox-web.teacherservices.cloud | External users (e.g. lead providers) | Explore the service without affecting production data | Merge to `main` | production | [View](https://npq-registration-sandbox-web.teacherservices.cloud/healthcheck.json) |
| Staging | https://npq-registration-staging-web.test.teacherservices.cloud | Team members | Production-like environment without real data | Merge to `main` | test | [View](https://npq-registration-staging-web.test.teacherservices.cloud/healthcheck.json)|
| Review | https://npq-registration-review-_PR-NUMBER_-web.test.teacherservices.cloud | Team members | Review changes prior to merging | Open a PR (auto-destroyed on merge/close) | test | Per-app |

Security in the `production` Azure space is configured for sensitive data. You need to log in with real admin credentials in these environments, and you'll need an Azure PIM to run `make` commands against them.

The `test` space should contain only seed/test data. Use dummy admin logins in these environments, and you won't need a PIM for `make`.
