module Statements
  class MarkAsPayable
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement

    def mark
      ApplicationRecord.transaction do
        declarations.find_each do |declaration|
          declaration_mark_as_payable_service.mark(declaration:)
        end
        statement.mark_payable!
      end
    end

  private

    def declarations
      statement.declarations.eligible_state
    end

    def declaration_mark_as_payable_service
      @declaration_mark_as_payable_service ||= Declarations::MarkAsPayable.new(statement:)
    end
  end
end
