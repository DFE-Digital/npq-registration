module Services
  class Feature
    REGISTRATION_OPEN_DATE = Time.zone.parse("6 June 2022 12:00")

    REGISTRATION_CLOSED_KEY = "Registration closed".freeze

    FEATURE_FLAG_KEYS = [
      REGISTRATION_CLOSED_KEY,
    ].freeze

    class << self
      def initialize_feature_flags
        FEATURE_FLAG_KEYS.each do |feature_flag_key|
          Flipper.add(feature_flag_key)
        end
        ENV["SERVICE_ENV"] == "sandbox" ? Flipper.enable(:maths_npq) : Flipper.disable(:maths_npq)
      end

      # This is always true but is checked so that it is explicit
      # why certain checks are made, rather than leaving implicit the reason behind TRN
      # presence checks. This also makes it clear what needs changing when TRNs become optional.
      #
      # Used in app/helpers/forms/flow_helper.rb to determine whether user's require TRNs
      # and should be directed to the qualified_teacher_check flow to enter a TRN if
      # the get an identity service did not provide one
      def trn_required?
        true
      end

      def registration_closed?
        Flipper.enabled?(REGISTRATION_CLOSED_KEY)
      end
    end
  end
end
