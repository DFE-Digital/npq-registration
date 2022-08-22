module Forms
  class YourEmployment < Base
    QUESTION_NAME = :employment_type

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def question
      OpenStruct.new(
        type: :radio_button_group,
        name: QUESTION_NAME,
        label: I18n.t("registration_wizard.your_employment.label"),
        options:,
      )
    end

    def options
      [
        build_option(value: "local_authority_virtual_school", link_errors: true),
        build_option(value: "hospital_school"),
        build_option(value: "young_offender_institution"),
        build_option(value: "local_authority_supply_teacher"),
        build_option(value: "other", divider: "or"),
      ].freeze
    end

    def next_step
      :your_role
    end

    def previous_step
      :qualified_teacher_check
    end

  private

    def locale_scope
      "registration_wizard.your_employment.options"
    end

    def build_option(value:, link_errors: false, divider: false)
      options = {
        value:,
        text: I18n.t(value, scope: locale_scope),
        link_errors:,
      }

      options[:divider] = divider if divider.present?

      OpenStruct.new(options)
    end
  end
end
