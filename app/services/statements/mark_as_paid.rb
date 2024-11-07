module Statements
  class MarkAsPaid
    def initialize(statement)
      @statement = statement
    end

    def mark
      Statement.transaction do
        statement
          .declarations
          .payable_state
          .each { |d| declaration_mark_as_paid_service.mark(d) }

        statement
          .declarations
          .awaiting_clawback_state
          .each(&:mark_clawed_back!)

        statement
          .statement_items
          .awaiting_clawback
          .each(&:mark_clawed_back!)

        statement.mark_paid!
      end
    end

  private

    attr_reader :statement

    def declaration_mark_as_paid_service
      @declaration_mark_as_paid_service ||= Declarations::MarkAsPaid.new(statement)
    end
  end
end
