# frozen_string_literal: true

module NpqSeparation
  module Admin
    class StatementDetailsComponent < BaseComponent
      attr_reader :statement, :calculator

      def initialize(statement:)
        @statement = statement
        @calculator = ::Statements::SummaryCalculator.new(statement:)
      end
    end
  end
end
