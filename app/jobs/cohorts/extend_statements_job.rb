# frozen_string_literal: true

module Cohorts
  class ExtendStatementsJob < ApplicationJob
    def perform(cohort_id:, **service_kwargs)
      cohort = Cohort.find(cohort_id)
      service = ExtendStatements.new(**service_kwargs.merge(cohort:))

      service.extend_statements!
    end
  end
end
