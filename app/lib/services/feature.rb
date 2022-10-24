module Services
  class Feature
    REGISTRATION_OPEN_DATE = Time.zone.parse("6 June 2022 12:00")

    GAI_INTEGRATION_KEY = "Get an Identity integration".freeze
    REGISTRATION_CLOSED_KEY = "Registration closed".freeze

    FEATURE_FLAG_KEYS = [
      GAI_INTEGRATION_KEY,
      REGISTRATION_CLOSED_KEY,
    ].freeze

    class << self
      def initialize_feature_flags
        FEATURE_FLAG_KEYS.each do |feature_flag_key|
          Flipper.add(feature_flag_key)
        end
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
