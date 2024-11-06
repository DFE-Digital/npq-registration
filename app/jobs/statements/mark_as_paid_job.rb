# frozen_string_literal: true

module Statements
  class MarkAsPaidJob < ApplicationJob
    discard_on StandardError do |_job, exception|
      Sentry.capture_exception(exception)
    end

    def perform(statement_id:)
      return unless statement_id

      statement = Statement.find_by(id: statement_id)

      if statement.present? && statement.payable?
        MarkAsPaid.new(statement).mark
      else
        Rails.logger.warn("Statement could not be found or is not payable - statement_id: #{statement_id}")
      end
    end
  end
end
