# frozen_string_literal: true

module Admin::Adjustments
  class CreateAdjustmentForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :created_adjustment_ids
    attribute :statement
    attribute :description
    attribute :amount, :integer
    attribute :adjustment

    validate :adjustment_valid
    validate :statement_open

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

    def statement_open
      return if statement.open?

      errors.add(:statement, :not_open)
    end
  end
end
