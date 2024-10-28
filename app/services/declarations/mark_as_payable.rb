# frozen_string_literal: true

module Declarations
  class MarkAsPayable
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement

    def mark(declaration:)
      ApplicationRecord.transaction do
        declaration.mark_payable!

        statement_item = statement
                      .statement_items
                      .find_by(declaration:)

        statement_item.mark_payable! if statement_item
      end
    end
  end
end
