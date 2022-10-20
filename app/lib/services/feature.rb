module Services
  class Feature
    REGISTRATION_CLOSED_KEY = "Registration closed"

    FEATURE_FLAG_KEYS = [
      REGISTRATION_CLOSED_KEY
    ]

    class << self
      def registration_closed?
        Flipper.enabled?(REGISTRATION_CLOSED_KEY)
      end
    end
  end
end
