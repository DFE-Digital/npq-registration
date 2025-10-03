# frozen_string_literal: true

module Admin::Adjustments
  class CreateAdjustmentForm
    include Concerns::AdjustmentForm

    attribute :created_adjustment_ids
    attribute :statement
    attribute :description
    attribute :amount, :decimal
    attribute :adjustment

    validate :adjustment_valid

    def initialize(*)
      super
      self.created_adjustment_ids ||= []
    end

    def save_adjustment
      return false unless valid?

      success = adjustment.save

      if success
        created_adjustment_ids << adjustment.id
      else
        errors.merge!(adjustment.errors)
      end

      success
    end

    def adjustments
      statement.adjustments.where(id: created_adjustment_ids)
    end

  private

    def adjustment
      @adjustment ||= statement.adjustments.new(description:, amount:)
    end

    def adjustment_valid
      errors.merge!(adjustment.errors) unless adjustment.valid?
    end
  end
end
