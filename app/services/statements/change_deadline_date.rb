# frozen_string_literal: true

module Statements
  class ChangeDeadlineDate
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
    include UpdatingAttributesIfAlreadyValid

    attribute :statement
    attribute :deadline_date

    validates :statement, presence: true, validate_and_copy_errors: true
    validates :deadline_date, presence: true

    validate :deadline_date_not_after_payment_date

    def change
      update_attributes_if_already_valid(statement, deadline_date: deadline_date)
    end

  private

    def deadline_date_not_after_payment_date
      return if errors.any?
      return unless statement.payment_date
      return unless deadline_date > statement.payment_date

      errors.add :deadline_date, :invalid
    end
  end
end
