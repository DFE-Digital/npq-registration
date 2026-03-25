module Questionnaires
  class ChoosePrivateChildcareProvider < Base
    include Helpers::Institution

    attribute :institution_name
    attribute :institution_identifier

    validates :institution_name, length: { maximum: 64 }
    validates :institution_name, presence: true, if: -> { institution_identifier.blank? || institution_identifier == "other" }

    validate :validate_institution_identifier
    validate :validate_private_childcare_provider_name_returns_results

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
      :choose_your_npq
    end

    def previous_step
      :have_ofsted_urn
    end

    def questions
      [
        QuestionTypes::AutoCompleteInstitution.new(
          name: :institution_identifier,
          locale_name: :choose_private_childcare_provider,
          picker: :"private-childcare-provider",
          options: possible_institutions,
          display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
          search_question: QuestionTypes::TextField.new(
            name: :institution_name,
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
      institution_name.present? || institution_identifier == "other"
    end

  private

    def validate_private_childcare_provider_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank? && institution_name.present?
        errors.add(:institution_name, :no_results, urn: institution_name)
      end
    end

    def validate_institution_identifier
      # return if no_js_fallback_search_loop?
      return if institution_identifier.blank? || institution_identifier == "other"

      unless institution_identifier.start_with?("PrivateChildcareProvider-")
        errors.add(:institution_identifier, :invalid, urn: institution_identifier)
      end

      return if institution(source: institution_identifier).present?

      errors.add(:institution_identifier, :no_results, urn: institution_identifier.split("-").last)
    end
  end
end
