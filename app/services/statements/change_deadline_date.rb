# frozen_string_literal: true

module Statements
  class ChangeDeadlineDate
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :statement
    attribute :deadline_date

    validates :statement, presence: true
    validates :deadline_date, presence: true

    validate :deadline_date_not_after_payment_date

    validate :statement_valid

    def change
      statement.deadline_date = deadline_date

      return false if invalid?

      statement.save # rubocop:disable Rails/SaveBang - return value is used by caller
    end

  private

    def deadline_date_not_after_payment_date
      return if errors.any?
      return unless statement.payment_date
      return unless deadline_date > statement.payment_date

      errors.add :deadline_date, :invalid
    end

    def statement_valid
      return if errors.any?
      return unless statement

      errors.merge!(statement.errors) unless statement.valid?
    end
  end
end
