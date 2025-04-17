module NpqSeparation
  module Admin
    class AdjustmentsTableComponent < ViewComponent::Base
      attr_reader :adjustments, :show_total

      def initialize(adjustments:, show_total: false)
        @adjustments = adjustments
        @show_total = show_total
      end
    end
  end
end
