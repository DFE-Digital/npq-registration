module Forms
  class WorkInNursery < Base
    VALID_WORK_IN_NURSERY_OPTIONS = %w[yes no].freeze

    attr_accessor :works_in_nursery

    validates :works_in_nursery, presence: true, inclusion: { in: VALID_WORK_IN_NURSERY_OPTIONS }

    def self.permitted_params
      %i[works_in_nursery]
    end

    def requirements_met?
      true
    end

    def next_step
      if works_in_nursery?
        :kind_of_nursery
      else
        :have_ofsted_urn
      end
    end

    def previous_step
      if wizard.tra_get_an_identity_omniauth_integration_active?
        :work_setting
      else
        :qualified_teacher_check
      end
    end

    def works_in_nursery?
      works_in_nursery == "yes"
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no"),
      ]
    end
  end
end
