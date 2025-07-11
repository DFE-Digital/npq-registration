# frozen_string_literal: true

module Admin::Adjustments
  class UpdateAdjustmentForm
    include Concerns::AdjustmentForm

    attribute :statement
    attribute :description
    attribute :amount, :integer
    attribute :adjustment

    validate :adjustment_valid

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
  end
end
