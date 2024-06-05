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
      elsif funding_eligibility.funded?
        wizard.store["senco_in_role_status"] = false
        :funding_eligibility_senco
      else
        wizard.store["senco_in_role_status"] = false

        if works_in_other?
          if funding_eligibility.funding_eligiblity_status_code == FundingEligibility::NO_INSTITUTION
            :possible_funding
          else
            :ineligible_for_funding
          end
        else
          :ineligible_for_funding
        end
      end
    end

    def previous_step
      :choose_your_npq
    end

    def funding_eligibility
      @funding_eligibility ||= FundingEligibility.new(
        course:,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        lead_mentor: lead_mentor_for_accredited_itt_provider?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn:,
        get_an_identity_id:,
        query_store:,
      )
    end

    delegate :course, :lead_mentor_for_accredited_itt_provider?, :new_headteacher?, :inside_catchment?,
             :approved_itt_provider?, :get_an_identity_id, :works_in_other?, :trn, to: :query_store
  end
end
