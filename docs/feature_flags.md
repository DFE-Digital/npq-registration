[< Back to Navigation](../README.md)

# Feature Flags

1. [What do we use to manage Feature Flags?](#what-do-we-use-to-manage-feature-flags)
1. [Who can manage feature flags?](#who-can-manage-feature-flags)
1. [How do I manage feature flags?](#how-do-i-manage-feature-flags)
1. [What feature flags are available and how do I create new ones?](#what-feature-flags-are-available-and-how-do-i-create-new-ones)
1. [How are feature flags used in the app?](#how-are-feature-flags-used-in-the-app)
1. [How are feature flags tied to users?](#how-are-feature-flags-tied-to-users)
1. [How do I enabled a feature flag for a percentage of users?](#how-do-i-enable-a-feature-flag-for-a-percentage-of-users)
1. [How do I turn a feature flag off for a user if it is enabled for everyone?](#how-do-i-turn-a-feature-flag-off-for-a-user-if-it-is-enabled-for-everyone)

## What do we use to manage Feature Flags?

The NPQ app uses [Flipper](https://github.com/jnunemaker/flipper) along with Flipper-UI
for managing feature flags.

This allows us to enable/disable features in production without having to deploy new code. This also brings us the ability to enable features for specific users, groups of users, or percentage of users. This allows us to manage slowly ramp up new features over time.

This has been used in the past for running a pilot of the Get an Identity service.

## Who can manage feature flags?

User's with the `superadmin` role can manage feature flags, see [Admins and Superadmins](docs/admins.md) for more information on these users.

## How do I manage feature flags?

To manage feature flags, you need to be logged in as a `superadmin` user. You can then visit the `/admin/feature_flags/features` path in the app. This is accessible within the admin interface by clicking on the `Feature Flags` link in the navigation.

Feature flags can then be fully enabled, disabled, or enabled for a percentage of users.

## What feature flags are available and how do I create new ones?

Feature flags supported by the app are defined in [Services::Feature](../app/lib/services/feature.rb), upon deployment any new feature flags will be created in the database and will be available to be managed. By default they will be turned off.

This is handled by the `feature_flags:initialize` rake task that is run as part of the deployment process.

## How are feature flags used in the app?

Feature flags can be checked using the standard Flipper syntax, for example:

```ruby
Flipper.enabled?(:my_feature_flag)
Flipper.enabled?(:my_feature_flag, current_user)
```

This will return true or false depending on whether the feature flag is enabled for the current user.

## How are feature flags tied to users

On User creation (when they returned from the Get an Identity service) they will have their feature flag ID that was set in their cookies tied to their User record, from then on this will be used for determining their feature flag status. This is typically only important for feature flags set on a percentage of users. 

## How do I enable a feature flag for a percentage of users?

When creating a new feature flag, you can set the percentage of users that the feature flag should be enabled for. This is done by setting the `percentage_of_users` field to a value between 0 and 100.

When checking the feature flag you should use the `Flipper.enabled?(:my_feature_flag, current_user)` syntax when checking if the flag is enabled. This will check if the feature flag is enabled for the current user, if it is not it will then check if the feature flag is enabled for a percentage of users and if the current user is within that percentage.

This will persist for the user as the percentage changes.

## How do I turn a feature flag off for a user if it is enabled for everyone?

By default, you cannot do this. Flipper does not provide the ability to turn a flag off for a user if it is enabled for a group they are within, and everyone counts as a group.

To handle this you need two feature flags, one that enables it, and a second override feature flag that turns it back off.

For example:

```ruby
def user_in_pilot?(current_user)
  Flipper.enabled?(:feature_pilot, current_user) && 
    !Flipper.enabled?(:removed_from_feature_pilot, current_user)
end
```

This would allow you to turn a feature off for a user if the feature has otherwise been turned on for everyone.
