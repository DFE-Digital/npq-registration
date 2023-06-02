[< Back to Navigation](../README.md)

# Maintenance Mode

1. [Enabling maintenance mode](#enabling-maintenance-mode)
1. [Disabling maintenance mode](#disabling-maintenance-mode)
1. [Helping users who try to register during maintenance mode](#helping-users-who-try-to-register-during-maintenance-mode)

The NPQ service has a maintenance mode that can be enabled to prevent users from accessing the service. This is useful when deploying changes to the service that require downtime or when the service is experiencing issues.

## Enabling maintenance mode

Maintenance mode can be enabled by toggling the `Registration Closed` feature flag in the NPQ feature flags interface (`/admin/feature_flags/features`) to "Fully Enabled". 

When enabled this flag will replace the standard start page with a page informing the user that registration is temporarily closed and invite them to register their interest.

Any users part way through the flow will be directed to the closed registration page when they try to move to the next step.

## Disabling maintenance mode

Maintenance mode can be disabled by toggling the `Registration Closed` feature flag in the NPQ feature flags interface (`/admin/feature_flags/features`) to "Fully Disabled".

This will reopen registration.

## Helping users who try to register during maintenance mode

User's who register their interest will have a record created in the `RegistrationInterest` table. Once maintenance mode is disabled this table can be used to contact these users and invite them to register. They can then be marked as notified by setting the `notified` column to `true`.
