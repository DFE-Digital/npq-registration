module Registration
  class CatchmentArea
    def initialize(teacher_catchment:, country_name: nil)
      @teacher_catchment = teacher_catchment
      @country_name = country_name
    end

    def teacher_catchment_country
      in_uk? ? uk_country.iso_short_name : @country_name
    end

    def teacher_catchment_iso_country_code
      return if teacher_catchment_country.blank?

      in_uk? ? uk_country.alpha3 : other_country&.alpha3
    end

  private

    def uk_country
      @uk_country ||= ISO3166::Country.find_country_by_any_name("United Kingdom")
    end

    def in_uk?
      @teacher_catchment.in?(Application::UK_CATCHMENT_AREA)
    end

    def other_country
      @other_country ||= lookup_country
    end

    def lookup_country
      ISO3166::Country
        .find_country_by_any_name(@country_name)
        .tap { |match| raise_warning unless match }
    end

    def raise_warning
      Sentry.capture_message("Could not find the ISO3166 alpha3 code for #{teacher_catchment_country}.", level: :warning)
    end
  end
end
