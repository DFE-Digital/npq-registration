module Questionnaires
  class EhcoNewHeadteacher < Base
    VALID_EHCO_NEW_HEADTEACHER_OPTIONS = %w[yes no].freeze

    attribute :ehco_new_headteacher

    validates :ehco_new_headteacher, presence: true, inclusion: { in: VALID_EHCO_NEW_HEADTEACHER_OPTIONS }

    def self.permitted_params
      %i[
        ehco_new_headteacher
      ]
    end

    def previous_step
      :npqh_status
    end

    def next_step
      wizard.store["ehco_new_headteacher"] = ehco_new_headteacher

      if funding_eligibility.funded?
        :ehco_possible_funding
      elsif funding_eligibility.subject_to_review?
        :possible_funding
      elsif query_store.declared_not_working_in_england?
        :funding_your_ehco
      else
        :ineligible_for_funding
      end
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(name: :ehco_new_headteacher, options:),
      ]
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no"),
      ]
    end

  private

    def funding_eligibility
      FundingEligibility.new_from_query_store(
        course:,
        institution: query_store.institution,
        approved_itt_provider: approved_itt_provider?,
        inside_catchment: inside_catchment?,
        user_ecf_id: query_store.user_ecf_id,
        query_store:,
      )
    end

    delegate :approved_itt_provider?,
             :course,
             :inside_catchment?,
             to: :query_store
  end
end
