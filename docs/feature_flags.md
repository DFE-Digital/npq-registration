[< Back to Navigation](../README.md)

# Feature Flags

1. [How do we use Feature Flags?](#how-do-we-use-feature-flags)
1. [How do I manage feature flags?](#how-do-i-manage-feature-flags)
1. [What feature flags are available and how do I create new ones?](#what-feature-flags-are-available-and-how-do-i-create-new-ones)
1. [How are feature flags used in the app?](#how-are-feature-flags-used-in-the-app)
1. [How are feature flags tied to users?](#how-are-feature-flags-tied-to-users)
1. [How do I turn a feature flag off for a user if it is enabled for everyone?](#how-do-i-turn-a-feature-flag-off-for-a-user-if-it-is-enabled-for-everyone)

## How do we use Feature Flags?

We use [Flipper](https://github.com/jnunemaker/flipper) to:

- enable/disable features in production without having to deploy new code
- enable features for specific users, groups of users, or percentage of users
- slowly ramp up new features over time.

## How do I manage feature flags?

To enable or disable feature flags for all users, log in to the admin console as a 'Super Admin' and then click on the `Feature Flags` link in the navigation.

To enable features for a subset of users, a developer needs to use a Rails console or write code for this to happen programatically.

## What feature flags are available and how do I create new ones?

Current feature flags are defined in [Feature](../app/services/feature.rb) by the `FEATURE_FLAG_KEYS` constant.

On deployment, new feature flags will be created and redundant ones will be deleted automatically according to this constant. By default, newly-created flags will be turned off.

This is handled by the `feature_flags:initialize` rake task that enhances `db:migrate`.

## How are feature flags used in the app?

Usually, a class method should be added to `Feature` following the existing convention. Feature flags can also be checked using the standard Flipper syntax, for example:

```ruby
Flipper.enabled?(:my_feature_flag)
Flipper.enabled?(:my_feature_flag, current_user)
```

This will return true or false depending on whether the feature flag is enabled for the current user.

## How are feature flags tied to users

On User creation (when they return from the Get an Identity service) they will have their feature flag ID that was set in their cookies tied to their User record, from then on this will be used for determining their feature flag status. This is typically only important for feature flags set on a percentage of users.

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
