module Questionnaires
  class ChooseYourProvider < Base
    include Helpers::Institution

    attr_accessor :lead_provider_id

    validates :lead_provider_id, presence: true
    validate :validate_lead_provider_exists

    def self.permitted_params
      %i[
        lead_provider_id
      ]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :lead_provider_id,
          body: I18n.t("helpers.hint.registration_wizard.lead_provider_id", course_name: course.name).html_safe,
          style_options: { hint: nil },
          options:,
        ),
      ]
    end

    def next_step
      :share_provider
    end

    def previous_step
      if course&.npqs? && wizard.query_store.inside_catchment?
        :funding_eligibility_senco
      elsif !wizard.query_store.inside_catchment? || !wizard.query_store.works_in_school?
        :funding_your_npq
      elsif course.npqh? && eligible_for_funding?
        :possible_funding
      elsif course.ehco?
        if eligible_for_funding?
          :ehco_possible_funding
        else
          :funding_your_ehco
        end
      else
        :choose_your_npq
      end
    end

    def options
      providers.each_with_index.map do |provider, index|
        build_option_struct(
          value: provider.id,
          label: provider.name,
          hint: provider.hint,
          link_errors: index.zero?,
        )
      end
    end

    def after_save
      # Not keen on this as adds a potential calculation and only really want to do this if the user has gone back a step
      wizard.store["funding_eligiblity_status_code"] = funding_eligibility_calculator.funding_eligiblity_status_code
    end

  private

    def eligible_for_funding?
      @eligible_for_funding ||= funding_eligibility_calculator.funded?
    end

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= FundingEligibility.new(
        course:,
        institution: institution(source: institution_identifier),
        approved_itt_provider: approved_itt_provider?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn:,
        get_an_identity_id:,
        query_store: wizard.query_store,
      )
    end

    def providers
      LeadProvider.for(course:).alphabetical
    end

    def lead_provider
      providers.find_by(id: lead_provider_id)
    end

    def institution_identifier
      wizard.store["institution_identifier"]
    end

    delegate :approved_itt_provider?,
             :course,
             :inside_catchment?,
             :new_headteacher?,
             :trn,
             :get_an_identity_id,
             to: :query_store

    def validate_lead_provider_exists
      if lead_provider.blank?
        errors.add(:lead_provider_id, :invalid)
      end
    end
  end
end
