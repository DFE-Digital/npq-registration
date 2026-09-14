# frozen_string_literal: true

module Declarations
  # Declaration totals for a lead provider and cohort.
  #
  # It follows the same rules as Statements::DeclarationsCalculator, but instead
  # of looking at a single statement it looks at the milestones of every past
  # output fee statement, and at every declaration received up to now.
  class DashboardCalculator < BaseDeclarationsCalculator
    attr_reader :lead_provider, :cohort

    def initialize(lead_provider:, cohort:)
      @lead_provider = lead_provider
      @cohort = cohort
      super()
    end

    def milestone_declaration_types
      @milestone_declaration_types ||= Milestone
        .joins(:statements)
        .where(statements: { id: past_statements })
        .distinct
        .pluck(:declaration_type)
    end

  private

    def declarations_scope
      Declaration.all
    end

    def past_statements
      Statement.where(cohort:, lead_provider:).with_output_fee.past
    end
  end
end
