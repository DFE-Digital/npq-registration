module Services
  class Feature
    REGISTRATION_OPEN_DATE = Time.zone.parse("6 June 2022 12:00")

    GAI_INTEGRATION_KEY = "Get an Identity integration".freeze
    REMOVE_USER_FROM_GAI_PILOT_KEY = "Disable Get an Identity pilot for user (for use with individual users)".freeze
    REGISTRATION_CLOSED_KEY = "Registration closed".freeze

    FEATURE_FLAG_KEYS = [
      GAI_INTEGRATION_KEY,
      REGISTRATION_CLOSED_KEY,
      REMOVE_USER_FROM_GAI_PILOT_KEY,
    ].freeze

    class << self
      def initialize_feature_flags
        FEATURE_FLAG_KEYS.each do |feature_flag_key|
          Flipper.add(feature_flag_key)
        end
      end

      def get_an_identity_integration_active_for?(user)
        Rails.logger.info(">>>>>>>>#{self.class}>>>>>>>>>>>>>>")
        Rails.logger.info("user: #{user}>>>>>>>>>>>>>>")
        Rails.logger.info("GAI_INTEGRATION_KEY?: #{Services::Feature::GAI_INTEGRATION_KEY}>>>>>>>>>>>>>>")
        Rails.logger.info("REMOVE_USER_FROM_GAI_PILOT_KEY?: #{Services::Feature::REMOVE_USER_FROM_GAI_PILOT_KEY}>>>>>>>>>>>>>>")
        Rails.logger.info(">>>>>>>>#{self.class}>>>>>>>>>>>>>>")

        Flipper.enabled?(Services::Feature::GAI_INTEGRATION_KEY, user) &&
          !Flipper.enabled?(Services::Feature::REMOVE_USER_FROM_GAI_PILOT_KEY, user)
      end

      def enroll_user_in_get_an_identity_pilot(user)
        Flipper.enable_actor(Services::Feature::GAI_INTEGRATION_KEY, user)
      end

      def remove_user_from_get_an_identity_pilot(user)
        Flipper.enable_actor(Services::Feature::REMOVE_USER_FROM_GAI_PILOT_KEY, user)
      end

      def registration_closed?
        Flipper.enabled?(REGISTRATION_CLOSED_KEY)
      end
    end
  end
end
