# frozen_string_literal: true

module Statements
  class ChangeOutputFeeJob < ApplicationJob
    def perform(statement_id:, **service_kwargs)
      statement = Statement.find(statement_id)
      service = ChangeOutputFee.new(**service_kwargs.merge(statement:))

      service.change_statement_and_reconcile!
    end
  end
end
