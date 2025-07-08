# frozen_string_literal: true

module Admin::Adjustments
  class DestroyAdjustmentForm
    include Concerns::AdjustmentForm

    attribute :statement
    attribute :adjustment

    delegate :id, :description, :amount, to: :adjustment

    def initialize(*)
      super
    end

    def destroy_adjustment
      return false unless valid?

      adjustment.destroy # rubocop:disable Rails/SaveBang - we don't want to raise an error if destroy fails

      adjustment.destroyed?
    end
  end
end
