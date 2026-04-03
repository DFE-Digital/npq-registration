module Questionnaires
  # This is for choosing *public* childcare providers, these are stored alongside schools in the educationl_institutions
  # table as type School, therefore, we search and display identically to as we do for schools
  class ChooseChildcareProvider < Base
    attribute :childcare_name
    attribute :childcare_identifier

    validates :childcare_identifier, format: { with: /\ASchool-\d{6,7}\z|\ALocalAuthority-\d+\z/, unless: -> { childcare_identifier.blank? || childcare_identifier == "other" } }
    validates :childcare_name, length: { maximum: 64 }
    validates :childcare_name, presence: true, if: -> { childcare_identifier.blank? || childcare_identifier == "other" }

    validate :validate_childcare_provider_name_returns_results

    def self.permitted_params
      %i[
        childcare_name
        childcare_identifier
      ]
    end

    def questions
      [
        QuestionTypes::AutoCompleteInstitution.new(
          name: :childcare_identifier,
          locale_name: :choose_childcare_provider,
          picker: :nursery,
          options: possible_institutions,
          display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
          search_question: QuestionTypes::TextField.new(
            name: :childcare_name,
            locale_name: :choose_childcare_provider_search,
          ),
        ),
      ]
    end

    # In the no js scenario we want the step to loop, showing a different screen
    # the second time but without showing an error - hence a negative response to
    # #valid? preventing saving but without appending errors
    def valid?(...)
      super(...) && childcare_identifier.present? && childcare_identifier != "other"
    end

    def next_step
      if institution.in_england? # Right now this is always true when it shouldn't be
        :choose_your_npq
      else
        :childcare_provider_not_in_england
      end
    end

    def previous_step
      :kind_of_nursery
    end

    def search_term_entered_in_no_js_fallback_form?
      # This combination of fields is only used in the no-js fallback form
      # childcare_name will be set from the search term being entered into the search
      # field that is only visible when JS is disabled.
      childcare_name.present? || childcare_identifier == "other"
    end

    def possible_institutions
      return @possible_institutions if @possible_institutions

      schools = School
                  .search_by_name(childcare_name)
                  .open
                  .limit(10)

      local_authorities = LocalAuthority
                            .search_by_name(childcare_name)
                            .limit(10)

      @possible_institutions = schools + local_authorities
    end

  private

    def institution
      ::Registration::Institution.fetch(identifier: childcare_identifier,
                                        works_in_school: false,
                                        works_in_childcare: true)
    end

    def institution_location
      wizard.store["institution_location"]
    end

    def validate_childcare_provider_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank? && childcare_name.present?
        errors.add(:childcare_name, :no_results, name: childcare_name)
      end
    end
  end
end
