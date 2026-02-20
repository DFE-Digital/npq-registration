# frozen_string_literal: true

module Statements
  class ChangePaymentDate
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
    include ModelAttributeUpdatable

    attribute :statement
    attribute :payment_date

    validates :statement, presence: true, valid: true
    validates :payment_date, presence: true

    validate :payment_date_not_before_deadline_date

    def change
      update_and_validate_attributes(statement, payment_date: payment_date)
    end

  private

    def payment_date_not_before_deadline_date
      return if errors.any?
      return unless statement.deadline_date
      return unless payment_date < statement.deadline_date

      errors.add :payment_date, :invalid
    end
  end
end
