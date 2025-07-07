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

    def change
      return false if invalid?

      statement.update(deadline_date:) # rubocop:disable Rails/SaveBang - return value is used by caller
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
