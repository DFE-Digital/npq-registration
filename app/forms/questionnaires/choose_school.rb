module Questionnaires
  class ChooseSchool < Base
    attribute :institution_name
    attribute :institution_identifier

    validates :institution_identifier, format: { with: /\ASchool-\d{6,7}\z|\ALocalAuthority-\d+\z/, unless: -> { institution_identifier.blank? || institution_identifier == "other" } }
    validates :institution_name, length: { maximum: 64 }
    validates :institution_name, presence: true, if: -> { institution_identifier.blank? || institution_identifier == "other" }

    validate :validate_school_name_returns_results

    def self.permitted_params
      %i[
        institution_name
        institution_identifier
      ]
    end

    # In the no js scenario we want the step to loop, showing a different screen
    # the second time but without showing an error - hence a negative response to
    # #valid? preventing saving but without appending errors
    def valid?(...)
      super(...) && institution_identifier.present? && institution_identifier != "other"
    end

    def next_step
      if institution.in_england?
        :choose_your_npq
      else
        :school_not_in_england
      end
    end

    def previous_step
      :work_setting
    end

    def questions
      [
        QuestionTypes::AutoCompleteInstitution.new(
          name: :institution_identifier,
          locale_name: :choose_school,
          picker: :school,
          options: possible_institutions,
          display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
          search_question: QuestionTypes::TextField.new(
            name: :institution_name,
            locale_name: :choose_school_search,
          ),
        ),
      ]
    end

    def possible_institutions
      return @possible_institutions if @possible_institutions

      schools = School
        .search_by_name(institution_name)
        .open
        .limit(10)

      local_authorities = LocalAuthority
        .search_by_name(institution_name)
        .limit(10)

      @possible_institutions = schools + local_authorities
    end

    def search_term_entered_in_no_js_fallback_form?
      # This combination of fields is only used in the no-js fallback form
      # institution_name will be set from the search term being entered into the search
      # field that is only visible when JS is disabled.
      institution_name.present? || institution_identifier == "other"
    end

  private

    def institution
      ::Registration::Institution.fetch(identifier: institution_identifier,
                                        works_in_school: true,
                                        works_in_childcare: false)
    end

    def validate_school_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank? && institution_name.present?
        errors.add(:institution_name, :no_results, name: institution_name)
      end
    end
  end
end
