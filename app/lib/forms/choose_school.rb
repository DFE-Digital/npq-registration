module Forms
  class ChooseSchool < Base
    include Helpers::Institution

    attr_accessor :institution_name, :institution_identifier

    validates :institution_identifier, format: { with: /\ASchool-\d{6,7}\z|\ALocalAuthority-\d+\z/, unless: -> { institution_identifier.blank? || institution_identifier == "other" } }
    validates :institution_name, length: { maximum: 64 }

    validate :validate_school_name_returns_results

    def self.permitted_params
      %i[
        institution_name
        institution_identifier
      ]
    end

    def next_step
      if institution_identifier == "other" || institution_identifier.blank?
        :choose_school
      elsif !institution(source: institution_identifier).in_england?
        :school_not_in_england
      else
        :choose_your_npq
      end
    end

    def previous_step
      :find_school
    end

    def question
      @question ||= Forms::QuestionTypes::AutoCompleteSchool.new(
        name: :institution_identifier,
        options: possible_institutions,
        locale_keys: {
          # This is here so that the question does not use institution_identifier as the locale key,
          # that question key is not specific to ChooseChildcareProvider so we need to use a more specific
          # key for finding the right locale string.
          name: :choose_school,
        },
        display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
        institution_location:,
        search_question: Forms::QuestionTypes::TextField.new(
          name: :institution_name,
          locale_keys: {
            # This is here so that the question does not use institution_name as the locale key,
            # that question key is not specific to ChooseChildcareProvider so we need to use a more specific
            # key for finding the right locale string.
            name: :choose_school_search,
          },
        ),
      )
    end

    def possible_institutions
      return @possible_institutions if @possible_institutions

      schools = School
        .open
        .search_by_location(institution_location)
        .search_by_name(institution_name)
        .limit(10)

      local_authorities = LocalAuthority
        .search_by_location(institution_location)
        .search_by_name(institution_name)
        .limit(10)

      @possible_institutions = schools + local_authorities
    end

  private

    def search_term_entered_in_no_js_fallback_form?
      # This combination of fields is only used in the no-js fallback form
      # institution_location will be set from the previous question
      # institution_name will be set from the search term being entered into the search
      # field that is only visible when JS is disabled.
      institution_location.present? && wizard.store["institution_name"].present?
    end

    def course
      @course ||= wizard.query_store.course
    end

    def institution_location
      wizard.store["institution_location"]
    end

    def validate_school_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank?
        errors.add(:institution_name, :no_results, location: institution_location, name: institution_name)
      end
    end
  end
end
