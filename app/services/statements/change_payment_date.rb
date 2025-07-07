# frozen_string_literal: true

module Statements
  class ChangePaymentDate
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :statement
    attribute :payment_date

    validates :statement, presence: true
    validates :payment_date, presence: true

    validate :payment_date_not_before_deadline_date

    def change
      return false if invalid?

      statement.update(payment_date:) # rubocop:disable Rails/SaveBang - return value is used by caller
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
