module Forms
  class AsoNewHeadteacher < Base
    VALID_ASO_NEW_HEADTEACHER_OPTIONS = %w[yes no].freeze

    include Helpers::Institution

    attr_accessor :aso_new_headteacher

    validates :aso_new_headteacher, presence: true, inclusion: { in: VALID_ASO_NEW_HEADTEACHER_OPTIONS }

    def self.permitted_params
      %i[
        aso_new_headteacher
      ]
    end

    def next_step
      case funding_eligiblity_status_code
      when :funded
        :aso_possible_funding
      when :previously_funded
        :aso_previously_funded
      else
        :aso_funding_not_available
      end
    end

    def previous_step
      :aso_headteacher
    end

    def question
      Forms::QuestionTypes::RadioButtonGroup.new(name: :aso_new_headteacher, options:)
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no"),
      ]
    end

  private

    def course
      wizard.query_store.course
    end

    def funding_eligiblity_status_code
      Services::FundingEligibility.new(
        course:,
        institution:,
        inside_catchment: wizard.query_store.inside_catchment?,
        approved_itt_provider: approved_itt_provider?,
        new_headteacher: new_headteacher?,
        trn: @wizard.query_store.trn,
      ).funding_eligiblity_status_code
    end

    delegate :approved_itt_provider?, to: :query_store

    def new_headteacher?
      aso_new_headteacher == "yes"
    end
  end
end
