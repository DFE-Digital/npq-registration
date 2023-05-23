module Forms
  # This is for choosing *public* childcare providers, these are stored alongside schools in the educationl_institutions
  # table as type School, therefore, we search and display identically to as we do for schools
  class ChooseChildcareProvider < Base
    include Helpers::Institution

    attr_accessor :institution_name, :institution_identifier

    validates :institution_identifier, format: { with: /\ASchool-\d{6,7}\z|\ALocalAuthority-\d+\z/, unless: -> { institution_identifier.blank? || institution_identifier == "other" } }
    validates :institution_name, length: { maximum: 64 }

    validate :validate_childcare_provider_name_returns_results

    def self.permitted_params
      %i[
        institution_name
        institution_identifier
      ]
    end

    def question
      @question ||= Forms::QuestionTypes::AutoCompleteInstitution.new(
        name: :institution_identifier,
        locale_name: :choose_childcare_provider,
        picker: :nursery,
        options: possible_institutions,
        data_attributes: { institution_location: },
        display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
        search_question: Forms::QuestionTypes::TextField.new(
          name: :institution_name,
          locale_name: :choose_childcare_provider_search,
        ),
      )
    end

    def next_step
      if institution_identifier == "other" || institution_identifier.blank?
        :choose_childcare_provider
      elsif !institution(source: institution_identifier).in_england? # Right now this is always true when it shouldn't be
        :childcare_provider_not_in_england
      else
        :choose_your_npq
      end
    end

    def previous_step
      :find_childcare_provider
    end

    def search_term_entered_in_no_js_fallback_form?
      # This combination of fields is only used in the no-js fallback form
      # institution_location will be set from the previous question
      # institution_name will be set from the search term being entered into the search
      # field that is only visible when JS is disabled.
      institution_location.present? && wizard.store["institution_name"].present?
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

    def institution_location
      wizard.store["institution_location"]
    end

    def validate_childcare_provider_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank?
        errors.add(:institution_name, :no_results, location: institution_location, name: institution_name)
      end
    end
  end
end
