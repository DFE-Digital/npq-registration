# frozen_string_literal: true

module Declarations
  class MarkAsPaid
    def initialize(statement)
      @statement = statement
    end

    def mark(declaration)
      Declaration.transaction do
        declaration.mark_paid!

        statement_item = statement
                          .statement_items
                          .find_by(declaration:)

        if statement_item && statement_item.payable?
          statement_item.mark_paid!
        end
      end
    end

  private

    attr_reader :statement
  end
end
