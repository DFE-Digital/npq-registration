module Questionnaires
  class CheckAnswersAndSubmit < Base
    def requirements_met?
      super &&
        query_store.course_start_cohort.present? &&
        query_store.course.present? &&
        query_store.work_setting.present? &&
        query_store.lead_provider.present? &&
        query_store.can_share_choices.present? &&
        query_store.funding_eligiblity_status_code.present?

      # TODO: NPQ-3956
      # where the above is minimal_requirements
      # if [
      #   FundingEligibility::FUNDED_ELIGIBILITY_RESULT,
      #   FundingEligibility::SUBJECT_TO_REVIEW,
      #   FundingEligibility::REFERRED_BY_RETURN_TO_TEACHING_ADVISER,
      # ].exclude?(query_store.funding_eligiblity_status_code)
      #   minimal_requirements && (query_store.funding.present? || query_store.ehco_funding_choice.present?)
      # else
      #   minimal_requirements
      # end
    end

    def step_requires_login?
      true
    end

    def last_step?
      true
    end

    def previous_step
      :share_provider
    end

    def next_step
      # This is the last step, so there is no next step.
    end

    def show_previously_funded_alert?
      wizard.store["pre_login_funding_eligiblity_status_code"] == FundingEligibility::FUNDED_ELIGIBILITY_RESULT && user_previously_funded?
    end

    def before_render
      wizard.store["previously_funded"] = true if user_previously_funded?
      wizard.store["funding_eligiblity_status_code"] = funding_eligibility_calculator.funding_eligiblity_status_code
    end

    def after_save
      wizard.store["email_template"] = email_template

      wizard.store["submitted"] = true
      wizard.session["clear_tra_login"] = true

      HandleSubmissionForStore.new(store: wizard.store).call
    end

    def email_template
      @email_template ||= EmailTemplate.call(data: wizard.store)
    end

    def change_path(step_id)
      if Rails.configuration.x.dfe_wizard
        wizard.resolve_step_path(step_id, return_to_review: step_id)
      else
        "/registration/#{step_id.to_s.dasherize}/change"
      end
    end
  end
end
