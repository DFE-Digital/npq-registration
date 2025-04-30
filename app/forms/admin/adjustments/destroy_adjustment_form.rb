# frozen_string_literal: true

module Admin::Adjustments
  class DestroyAdjustmentForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :statement
    attribute :adjustment

    validate :statement_open

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

    def statement_open
      return if statement.open?

      errors.add(:statement, :not_open)
    end
  end
end
