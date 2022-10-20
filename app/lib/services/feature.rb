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
      def get_an_identity_integration_active_for?(user)
        Flipper.enabled?(Services::Feature::GAI_INTEGRATION_KEY, user)
      end

      def registration_closed?
        Flipper.enabled?(REGISTRATION_CLOSED_KEY)
      end
    end
  end
end
