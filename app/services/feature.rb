class Feature
  REGISTRATION_OPEN_DATE = Time.zone.parse("6 June 2022 12:00")

  REGISTRATION_OPEN = "Registration open".freeze
  REGISTRATION_DISABLED = "Registration disabled".freeze
  CLOSED_REGISTRATION_ENABLED = "Closed registration enabled".freeze
  DFE_ANALYTICS_ENABLED = "DfE Analytics Enabled".freeze
  MAINTENANCE_BANNER = "Maintenance banner".freeze
  DECLARATIONS_REQUIRE_DELIVERY_PARTNER = "Declarations require delivery partner".freeze
  INCLUDE_DELIVERY_PARTNERS_IN_DECLARATIONS_API = "Include delivery partners in declarations API".freeze

  # This constant 'registers' all the feature flags we are using. We must not use a feature flag that is
  # not included in this array. This approach will make tracking feature flags much easier.
  FEATURE_FLAG_KEYS = [
    REGISTRATION_OPEN,
    CLOSED_REGISTRATION_ENABLED,
    MAINTENANCE_BANNER,
    DFE_ANALYTICS_ENABLED,
    DECLARATIONS_REQUIRE_DELIVERY_PARTNER,
    INCLUDE_DELIVERY_PARTNERS_IN_DECLARATIONS_API,
  ].freeze

  class << self
    def initialize_feature_flags
      FEATURE_FLAG_KEYS.each do |feature_flag_key|
        Flipper.add(feature_flag_key)
      end

      redundant.each(&:remove)
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

    def registration_closed?(user)
      !Flipper.enabled?(REGISTRATION_OPEN, user)
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

    def maintenance_banner_enabled?
      Flipper.enabled?(MAINTENANCE_BANNER)
    end

    def dfe_analytics_enabled?
      Flipper.enabled?(DFE_ANALYTICS_ENABLED)
    end

    def declarations_require_delivery_partner?
      Flipper.enabled?(DECLARATIONS_REQUIRE_DELIVERY_PARTNER)
    end

    def include_delivery_partners_in_declarations_api?
      Flipper.enabled?(INCLUDE_DELIVERY_PARTNERS_IN_DECLARATIONS_API)
    end

  private

    def redundant
      Flipper.features.reject { _1.name.in? FEATURE_FLAG_KEYS }
    end
  end
end
