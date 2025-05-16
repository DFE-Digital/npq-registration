module NpqSeparation
  module Admin
    class AdjustmentsTableComponent < ViewComponent::Base
      attr_reader :adjustments, :show_total, :show_actions, :show_all_adjustments

      def initialize(adjustments:, show_total: false, show_actions: false, show_all_adjustments: false)
        @adjustments = adjustments
        @show_total = show_total
        @show_actions = show_actions
        @show_all_adjustments = show_all_adjustments
      end
    end
  end
end
