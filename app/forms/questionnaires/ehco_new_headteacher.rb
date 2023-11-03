module Questionnaires
  class EhcoNewHeadteacher < Base
    VALID_EHCO_NEW_HEADTEACHER_OPTIONS = %w[yes no].freeze

    include Helpers::Institution

    attr_accessor :ehco_new_headteacher

    validates :ehco_new_headteacher, presence: true, inclusion: { in: VALID_EHCO_NEW_HEADTEACHER_OPTIONS }

    def self.permitted_params
      %i[
        ehco_new_headteacher
      ]
    end

    def next_step
      case funding_eligiblity_status_code
      when Services::FundingEligibility::FUNDED_ELIGIBILITY_RESULT
        :ehco_possible_funding
      when Services::FundingEligibility::PREVIOUSLY_FUNDED
        :ehco_previously_funded
      else
        :ehco_funding_not_available
      end
    end

    def previous_step
      :ehco_headteacher
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

    def funding_eligiblity_status_code
      Services::FundingEligibility.new(
        course:,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn:,
        get_an_identity_id:,
      ).funding_eligiblity_status_code
    end

    delegate :approved_itt_provider?,
             :course,
             :inside_catchment?,
             :trn,
             :get_an_identity_id,
             to: :query_store

    def new_headteacher?
      ehco_new_headteacher == "yes"
    end
  end
end
