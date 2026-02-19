# frozen_string_literal: true

module Statements
  class ChangePaymentDate
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :statement
    attribute :payment_date

    validates :statement, presence: true, valid: true
    validates :payment_date, presence: true

    validate :payment_date_not_before_deadline_date

    def change
      statement.payment_date = payment_date

      return false if invalid?

      statement.save # rubocop:disable Rails/SaveBang - return value is used by caller
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
