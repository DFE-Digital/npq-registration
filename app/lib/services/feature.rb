module Services
  class Feature
    REGISTRATION_OPEN_DATE = Time.zone.parse("6 June 2022 12:00")

    GAI_INTEGRATION_KEY = "Get an Identity integration".freeze
    REGISTRATION_CLOSED_KEY = "Registration closed".freeze
    CURRENT_USER_FEATURE_FLAG_MANAGER_ACTIVE = "Current user feature flag manager active".freeze

    FEATURE_FLAG_KEYS = [
      GAI_INTEGRATION_KEY,
      REGISTRATION_CLOSED_KEY,
      CURRENT_USER_FEATURE_FLAG_MANAGER_ACTIVE,
    ].freeze

    # When CURRENT_USER_FEATURE_FLAG_MANAGER_ACTIVE is turned on users can visit /feature_flags
    # to see which feature flags are enabled for them and which aren't. They can also turn them on
    # and off for themselves. This is for testing purposes.
    # This array is used to prevent users from turning on and off feature flags that we allow them to
    # toggle on and off for themselves.
    FLIPPABLE_BY_USER = [
      GAI_INTEGRATION_KEY,
    ].freeze

    class << self
      def initialize_feature_flags
        FEATURE_FLAG_KEYS.each do |feature_flag_key|
          Flipper.add(feature_flag_key)
        end
      end

      def feature_flag_flippable_by_user?(feature_flag)
        return false unless users_can_flip_own_flags?

        FLIPPABLE_BY_USER.include?(feature_flag)
      end

      def users_can_flip_own_flags?
        Flipper.enabled?(CURRENT_USER_FEATURE_FLAG_MANAGER_ACTIVE)
      end

      def get_an_identity_integration_active_for?(user)
        Flipper.enabled?(Services::Feature::GAI_INTEGRATION_KEY, user)
      end

      def registration_closed?
        Flipper.enabled?(REGISTRATION_CLOSED_KEY)
      end
    end
  end
end
