module Forms
  class ChoosePrivateChildcareProvider < Base
    include Helpers::Institution

    attr_accessor :institution_name, :institution_identifier

    validates :institution_name, length: { maximum: 64 }

    validate :validate_institution_identifier
    validate :validate_private_childcare_provider_name_returns_results

    def self.permitted_params
      %i[
        institution_name
        institution_identifier
      ]
    end

    def next_step
      if no_js_fallback_search_loop? || institution_identifier.blank?
        :choose_private_childcare_provider
      else
        :choose_your_npq
      end
    end

    def previous_step
      :have_ofsted_urn
    end

    def question
      @question ||= Forms::QuestionTypes::AutoCompletePrivateChildcareProvider.new(
        name: :institution_identifier,
        options: possible_institutions,
        locale_keys: {
          # This is here so that the question does not use institution_identifier as the locale key,
          # that question key is not specific to ChooseChildcareProvider so we need to use a more specific
          # key for finding the right locale string.
          name: :choose_private_childcare_provider,
        },
        display_no_javascript_fallback_form: search_term_entered_in_no_js_fallback_form?,
        search_question: Forms::QuestionTypes::TextField.new(
          name: :institution_name,
          locale_keys: {
            # This is here so that the question does not use institution_name as the locale key,
            # that question key is not specific to ChooseChildcareProvider so we need to use a more specific
            # key for finding the right locale string.
            name: :choose_private_childcare_provider_search,
          },
        ),
      )
    end

    def possible_institutions
      return @possible_institutions if @possible_institutions

      @possible_institutions = PrivateChildcareProvider
                                .search_by_urn(institution_name)
                                .limit(10)
    end

  private

    def search_term_entered_in_no_js_fallback_form?
      wizard.store["institution_name"].present?
    end

    def no_js_fallback_search_loop?
      institution_identifier == "other"
    end

    def validate_private_childcare_provider_name_returns_results
      if search_term_entered_in_no_js_fallback_form? && possible_institutions.blank?
        errors.add(:institution_name, :no_results, urn: institution_name)
      end
    end

    def validate_institution_identifier
      return if no_js_fallback_search_loop?
      return if institution_identifier.blank?

      errors.add(:institution_identifier, :invalid, urn: institution_identifier) unless
        institution_identifier.start_with?("PrivateChildcareProvider-")

      return if institution(source: institution_identifier).present?

      errors.add(:institution_identifier, :no_results, urn: institution_identifier.split("-").last)
    end
  end
end
