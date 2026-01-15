# frozen_string_literal: true

module NpqSeparation
  module Admin
    class StatementSummaryComponent < BaseComponent
      include StatementHelper

      attr_reader :calculator, :link_to_voids, :statement, :declarations_calculator

      def initialize(statement:, link_to_voids: true)
        @calculator = ::Statements::SummaryCalculator.new(statement:)
        @declarations_calculator = ::Statements::DeclarationsCalculator.new(statement: statement)
        @link_to_voids = link_to_voids
        @statement = statement
      end
    end
  end
end
