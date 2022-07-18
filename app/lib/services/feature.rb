module Services
  class Feature
    REGISTRATION_CLOSE_DATE = Time.zone.parse("12 March 2022 00:00")
    REGISTRATION_OPEN_DATE = Time.zone.parse("6 June 2022 12:00")
    REGISTRATION_CLOSED = (REGISTRATION_CLOSE_DATE..REGISTRATION_OPEN_DATE)

    class << self
      def registration_closed?
        features_enabled? && (registration_closed_due_to_timing? || registration_closed_via_env_variable?)
      end

      # We only enable these feature in prod.
      def features_enabled?
        ENV["SERVICE_ENV"] == "production"
      end

      def registration_closed_due_to_timing?
        REGISTRATION_CLOSED.cover?(Time.zone.now)
      end

      def registration_closed_via_env_variable?
        ENV.fetch("REGISTRATION_CLOSED", "false") == "true"
      end
    end
  end
end
