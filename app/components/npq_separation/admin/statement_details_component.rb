# frozen_string_literal: true

module NpqSeparation
  module Admin
    class StatementDetailsComponent < BaseComponent
      attr_reader :calculator, :link_to_voids, :statement

      def initialize(statement:, link_to_voids: true)
        @calculator = ::Statements::SummaryCalculator.new(statement:)
        @link_to_voids = link_to_voids
        @statement = statement
      end
    end
  end
end
