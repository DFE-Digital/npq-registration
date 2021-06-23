module Forms
  class ChooseYourProvider < Base
    attr_accessor :lead_provider_id

    validates :lead_provider_id, presence: true
    validate :validate_lead_provider_exists

    def self.permitted_params
      %i[
        lead_provider_id
      ]
    end

    def next_step
      if changing_answer?
        :check_answers
      else
        :find_school
      end
    end

    def previous_step
      if wizard.form_for_step(:choose_your_npq).studying_for_headship?
        :headteacher_duration
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

    def validate_lead_provider_exists
      if lead_provider.blank?
        errors.add(:lead_provider_id, :invalid)
      end
    end
  end
end
