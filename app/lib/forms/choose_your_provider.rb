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
      :check_answers
    end

    def previous_step
      if course.npqh?
        :headteacher_duration
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
      Services::FundingEligibility.new(course: course, institution: institution(source: institution_identifier), headteacher_status: headteacher_status).call
    end

    def institution_identifier
      wizard.store["institution_identifier"]
    end

    def headteacher_status
      wizard.store["headteacher_status"]
    end

    def validate_lead_provider_exists
      if lead_provider.blank?
        errors.add(:lead_provider_id, :invalid)
      end
    end
  end
end
