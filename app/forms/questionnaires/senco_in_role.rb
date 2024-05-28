module Questionnaires
  class SencoInRole < Base
    include Helpers::Institution

    QUESTION_NAME = :senco_in_role

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :senco_in_role,
          options:,
          style_options: { legend: { size: "xl", tag: "h1" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no_but_i_plan_to_become_one", link_errors: true),
        build_option_struct(value: "no_i_do_not_plan_to_be_a_SENCO", link_errors: true),
      ]
    end

    def next_step
      if senco_in_role == "yes"
        wizard.store["senco_in_role_status"] = true
        :senco_start_date
      elsif query_store.kind_of_nursery_private? && !query_store.has_ofsted_urn?
        wizard.store["senco_in_role_status"] = false
        :ineligible_for_funding
      else
        wizard.store["senco_in_role_status"] = false
        if wizard.query_store.inside_catchment?
          :funding_eligibility_senco
        else
          :ineligible_for_funding
        end
      end
    end

    def previous_step
      :choose_your_npq
    end
  end
end
