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
      elsif course.aso? && wizard.store["aso_funding"] == "yes"
        :funding_your_aso
      elsif wizard.store["aso_new_headteacher"] == "yes"
        :aso_possible_funding
      else
        :choose_your_npq
      end
    end

    def options
      LeadProvider.all.each_with_index.map do |provider, index|
        OpenStruct.new(value: provider.id,
                       text: provider.name,
                       link_errors: index.zero?)
      end
    end

    def lead_provider
      LeadProvider.find_by(id: lead_provider_id)
    end

    def course
      Course.find_by(id: wizard.store["course_id"])
    end

  private

    def eligible_for_funding?
      Services::FundingEligibility.new(
        course: course,
        institution: institution(source: institution_identifier),
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
      ).funded?
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
