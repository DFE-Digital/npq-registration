module Questionnaires
  class WorkSetting < Base
    A_SCHOOL = "a_school".freeze
    AN_ACADEMY_TRUST = "an_academy_trust".freeze
    A_16_TO_19_EDUCATIONAL_SETTING = "a_16_to_19_educational_setting".freeze

    SCHOOL_SETTINGS = [
      A_SCHOOL,
      AN_ACADEMY_TRUST,
      A_16_TO_19_EDUCATIONAL_SETTING,
    ].freeze

    CHILDCARE_SETTINGS = %w[
      early_years_or_childcare
    ].freeze

    ANOTHER_SETTING_SETTINGS = %w[
      another_setting
    ].freeze

    OTHER_SETTINGS = %w[
      other
    ].freeze

    ALL_SETTINGS = [SCHOOL_SETTINGS, CHILDCARE_SETTINGS, ANOTHER_SETTING_SETTINGS, OTHER_SETTINGS].flatten

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

        %w[kind_of_nursery has_ofsted_urn].map { |field| wizard.store.delete(field) }
      when *CHILDCARE_SETTINGS
        wizard.store["works_in_childcare"] = "yes"
        wizard.store["works_in_school"] = "no"
      when *OTHER_SETTINGS, *ANOTHER_SETTING_SETTINGS
        wizard.store["works_in_school"] = "no"
        wizard.store["works_in_childcare"] = "no"

        %w[funding kind_of_nursery has_ofsted_urn].map do |field|
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
      if wizard.query_store.inside_catchment?
        return :find_school if works_in_school?
        return :kind_of_nursery if works_in_childcare?
        return :referred_by_return_to_teaching_adviser if works_in_other?

        return :your_employment
      end

      :choose_your_npq
    end

    def previous_step
      :teacher_catchment
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :work_setting,
          options:,
          style_options: {
            hint: { text: I18n.t("helpers.hint.registration_wizard.work_setting") },
            width: "three-quarters",
          },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "early_years_or_childcare", link_errors: true),
        build_option_struct(value: "a_school"),
        build_option_struct(value: "an_academy_trust"),
        build_option_struct(value: "a_16_to_19_educational_setting"),
        build_option_struct(value: "another_setting"),
        build_option_struct(value: "other", divider: true),
      ]
    end

  private

    def build_option_struct(**kwargs)
      super(**kwargs.deep_merge(label: { size: "s" }))
    end

    def works_in_school?
      SCHOOL_SETTINGS.include?(work_setting)
    end

    def works_in_childcare?
      CHILDCARE_SETTINGS.include?(work_setting)
    end

    def works_in_another_setting?
      ANOTHER_SETTING_SETTINGS.include?(work_setting)
    end

    def works_in_other?
      OTHER_SETTINGS.include?(work_setting)
    end
  end
end
