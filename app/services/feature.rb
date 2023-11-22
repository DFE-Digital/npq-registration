class Feature
  REGISTRATION_OPEN_DATE = Time.zone.parse("6 June 2022 12:00")

  REGISTRATION_CLOSED_KEY = "Registration closed".freeze
  REGISTRATION_DISABLED = "Registration disabled".freeze

  FEATURE_FLAG_KEYS = [
    REGISTRATION_CLOSED_KEY,
  ].freeze

  class << self
    def initialize_feature_flags
      FEATURE_FLAG_KEYS.each do |feature_flag_key|
        Flipper.add(feature_flag_key)
      end
      Flipper.enable(:maths_npq)
      Flipper.disable(:targeted_support_funding)
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

    def registration_disabled?
      Flipper.enabled?(REGISTRATION_DISABLED)
    end

    def registration_enabled?
      !Flipper.enabled?(REGISTRATION_DISABLED)
    end

    def disable_registration!
      Flipper.enable(REGISTRATION_DISABLED)
    end

    def enable_registration!
      Flipper.disable(REGISTRATION_DISABLED)
    end
  end
end
