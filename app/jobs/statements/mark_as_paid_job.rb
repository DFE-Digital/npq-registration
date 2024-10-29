# frozen_string_literal: true

module Statements
  class MarkAsPaidJob < ApplicationJob
    def perform(statement_id:)
      return unless statement_id

      statement = Statement.find_by(id: statement_id)

      if statement.present? && statement.payable?
        MarkAsPaid.new(statement).mark
      else
        Rails.logger.warn("Statement could not be found - statement_id: #{statement_id}")
      end
    end
  end
end
