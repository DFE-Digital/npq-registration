module Forms
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

    def next_step
      :share_provider
    end

    def previous_step
      if !wizard.query_store.inside_catchment? || !wizard.query_store.works_in_school?
        :funding_your_npq
      elsif course.npqh? && eligible_for_funding?
        :possible_funding
      elsif course.ehco?
        if eligible_for_funding?
          :aso_possible_funding
        else
          :funding_your_aso
        end
      else
        :choose_your_npq
      end
    end

    def options
      providers.each_with_index.map do |provider, index|
        OpenStruct.new(
          value: provider.id,
          text: provider.name,
          hint: provider.hint,
          link_errors: index.zero?,
        )
      end
    end

    def lead_provider
      providers.find_by(id: lead_provider_id)
    end

    def course
      wizard.query_store.course
    end

  private

    def eligible_for_funding?
      @eligible_for_funding ||= Services::FundingEligibility.new(
        course:,
        institution: institution(source: institution_identifier),
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
      ).funded?
    end

    def providers
      LeadProvider.for(course:).alphabetical
    end

    def institution_identifier
      wizard.store["institution_identifier"]
    end

    delegate :new_headteacher?, :inside_catchment?, to: :query_store

    def validate_lead_provider_exists
      if lead_provider.blank?
        errors.add(:lead_provider_id, :invalid)
      end
    end
  end
end
