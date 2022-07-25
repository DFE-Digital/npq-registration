module Forms
  class WorkSetting < Base
    VALID_WORK_SETTING_OPTIONS = %w[early_years_or_childcare a_school an_academy_trust a_16_to_19_educational_setting other].freeze

    attr_accessor :work_setting

    validates :work_setting, presence: true, inclusion: { in: VALID_WORK_SETTING_OPTIONS }

    def self.permitted_params
      %i[work_setting]
    end

    def after_save
      # we are inferring `works_in_school` and `works_in_childcare` to maintain
      # consistency with older records

      case work_setting
      when "a_school", "an_academy_trust", "a_16_to_19_educational_setting"
        wizard.store["works_in_school"] = "yes"
        wizard.store["works_in_childcare"] = "no"
        wizard.store["works_in_nursery"] = nil
      when "early_years_or_childcare"
        wizard.store["works_in_childcare"] = "yes"
        wizard.store["works_in_school"] = "no"
        wizard.store["works_in_nursery"] ||= nil
      when "other"
        wizard.store["works_in_school"] = "no"
        wizard.store["works_in_childcare"] = "no"
        wizard.store["works_in_nursery"] = nil
      else
        raise(ArgumentError, "invalid work setting #{work_setting}")
      end
    end

    def requirements_met?
      true
    end

    def return_to_regular_flow_on_change?
      true
    end

    def next_step
      :teacher_reference_number
    end

    def previous_step
      :teacher_catchment
    end
  end
end
