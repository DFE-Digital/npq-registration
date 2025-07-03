# frozen_string_literal: true

module Admin::Adjustments
  class DestroyAdjustmentForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement
    attribute :adjustment

    validate :adjustments_allowed

    delegate :id, :description, :amount, to: :adjustment

    def initialize(*)
      super
    end

    def destroy_adjustment
      return false unless valid?

      adjustment.destroy # rubocop:disable Rails/SaveBang - we don't want to raise an error if destroy fails

      adjustment.destroyed?
    end

  private

    def adjustments_allowed
      return unless statement.paid?

      errors.add(:statement, :adjustments_not_allowed)
    end
  end
end
