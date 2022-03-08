module Services
  class Feature
    REGISTRATION_CLOSED = (Time.zone.parse("12 March 00:00")..).freeze

    class << self
      def registration_closed?
        REGISTRATION_CLOSED.cover?(Time.zone.now)
      end
    end
  end
end
