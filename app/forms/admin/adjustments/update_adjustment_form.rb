# frozen_string_literal: true

module Admin::Adjustments
  class UpdateAdjustmentForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement
    attribute :description
    attribute :amount, :integer
    attribute :adjustment

    validate :adjustment_valid
    validate :statement_open

    delegate :id, to: :adjustment

    def initialize(*)
      super
    end

    def save_adjustment
      adjustment.description = description
      adjustment.amount = amount

      return false unless valid?

      adjustment.save # rubocop:disable Rails/SaveBang - result used by caller
    end

  private

    def adjustment_valid
      errors.merge!(adjustment.errors) unless adjustment.valid?
    end

    def statement_open
      return if statement.open?

      errors.add(:statement, :not_open)
    end
  end
end
