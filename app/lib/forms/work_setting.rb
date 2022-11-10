module Forms
  class WorkSetting < Base
    SCHOOL_SETTINGS = %w[
      a_school
      an_academy_trust
      a_16_to_19_educational_setting
    ].freeze

    CHILDCARE_SETTINGS = %w[
      early_years_or_childcare
    ].freeze

    OTHER_SETTINGS = %w[
      other
    ].freeze

    ALL_SETTINGS = [SCHOOL_SETTINGS, CHILDCARE_SETTINGS, OTHER_SETTINGS].flatten

    attr_accessor :work_setting

    validates :work_setting, presence: true, inclusion: { in: ALL_SETTINGS }

    def self.permitted_params
      %i[work_setting]
    end

    def after_save
      # we are inferring `works_in_school` and `works_in_childcare` to maintain
      # consistency with older records

      case work_setting
      when *SCHOOL_SETTINGS
        wizard.store["works_in_school"] = "yes"
        wizard.store["works_in_childcare"] = "no"

        %w[works_in_nursery kind_of_nursery has_ofsted_urn].map { |field| wizard.store.delete(field) }
      when *CHILDCARE_SETTINGS
        wizard.store["works_in_childcare"] = "yes"
        wizard.store["works_in_school"] = "no"
      when *OTHER_SETTINGS
        wizard.store["works_in_school"] = "no"
        wizard.store["works_in_childcare"] = "no"

        %w[funding works_in_nursery kind_of_nursery has_ofsted_urn].map do |field|
          wizard.store.delete(field)
        end
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
      if wizard.tra_get_an_identity_omniauth_integration_active?
        if wizard.query_store.inside_catchment?
          return :find_school if works_in_school?
          return :work_in_nursery if works_in_childcare?

          return :your_employment
        end

        :choose_your_npq
      else
        return :contact_details if works_in_other?

        :teacher_reference_number
      end
    end

    def previous_step
      :teacher_catchment
    end

  private

    def works_in_school?
      SCHOOL_SETTINGS.include?(work_setting)
    end

    def works_in_childcare?
      CHILDCARE_SETTINGS.include?(work_setting)
    end

    def works_in_other?
      OTHER_SETTINGS.include?(work_setting)
    end
  end
end
