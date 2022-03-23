module Services
  class Feature
    REGISTRATION_CLOSED = (Time.zone.parse("12 March 00:00")..).freeze

    class << self
      def registration_closed?
        features_enabled? && REGISTRATION_CLOSED.cover?(Time.zone.now)
      end

      # We only enable these feature in prod.
      def features_enabled?
        ENV["SERVICE_ENV"] == "production"
      end
    end
  end
end
