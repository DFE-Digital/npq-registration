module Questionnaires
  class ChoosePrivateChildcareProvider < Base
    attribute :private_childcare_name
    attribute :private_childcare_identifier

    validates :private_childcare_name, length: { maximum: 64 }
    validates :private_childcare_name, presence: true, if: -> { private_childcare_identifier.blank? || private_childcare_identifier == "other" }

    validate :validate_private_childcare_identifier
    validate :validate_private_childcare_provider_name_returns_results

    def self.permitted_params
      %i[
        private_childcare_name
        private_childcare_identifier
      ]
    end

    # In the no js scenario we want the step to loop, showing a different screen
    # the second time but without showing an error - hence a negative response to
    # #valid? preventing saving but without appending errors
    def valid?(...)
      super(...) && private_childcare_identifier.present? && private_childcare_identifier != "other"
    end

    def next_step
      :choose_your_npq
    end

    def previous_step
      :have_ofsted_urn
    end

    def questions
      [
        QuestionTypes::AutoCompleteInstitution.new(
          name: :private_childcare_identifier,
          locale_name: :choose_private_childcare_provider,
          picker: :"private-childcare-provider",
          options: possible_institutions,
          display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
          search_question: QuestionTypes::TextField.new(
            name: :private_childcare_name,
            locale_name: :choose_private_childcare_provider_search,
          ),
        ),
      ]
    end

    def possible_institutions
      return @possible_institutions if @possible_institutions

      @possible_institutions = PrivateChildcareProvider.limit(10)
    end

    def search_term_entered_in_no_js_fallback_form?
      private_childcare_name.present? || private_childcare_identifier == "other"
    end

  private

    def institution
      ::Registration::Institution.fetch(identifier: private_childcare_identifier,
                                        works_in_school: false,
                                        works_in_childcare: true)
    end

    def validate_private_childcare_provider_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank? && private_childcare_name.present?
        errors.add(:private_childcare_name, :no_results, urn: private_childcare_name)
      end
    end

    def validate_private_childcare_identifier
      return if private_childcare_identifier.blank? || private_childcare_identifier == "other"

      unless private_childcare_identifier.start_with?("PrivateChildcareProvider-")
        errors.add(:private_childcare_identifier, :invalid, urn: private_childcare_identifier)
      end

      return if institution.present?

      errors.add(:private_childcare_identifier, :no_results, urn: private_childcare_identifier.split("-").last)
    end
  end
end
