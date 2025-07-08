module Admin::Adjustments
  module Concerns
    module AdjustmentForm
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model
        include ActiveModel::Attributes

        validate :adjustments_allowed
      end

    private

      def adjustments_allowed
        return unless statement.paid?

        errors.add(:statement, :adjustments_not_allowed)
      end
    end
  end
end
