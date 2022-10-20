module Services
  class Feature
    REGISTRATION_OPEN_DATE = Time.zone.parse("6 June 2022 12:00")

    REGISTRATION_CLOSED_KEY = "Registration closed".freeze

    FEATURE_FLAG_KEYS = [
      REGISTRATION_CLOSED_KEY,
    ].freeze

    class << self
      def registration_closed?
        Flipper.enabled?(REGISTRATION_CLOSED_KEY)
      end
    end
  end
end
