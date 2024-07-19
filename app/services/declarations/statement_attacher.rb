# frozen_string_literal: true

module Declarations
  class StatementAttacher
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declaration

    validates :declaration, presence: true
    validate :next_output_fee_statement_exists
    validate :declaration_has_attachable_state

    def attach
      return false if invalid?

      ApplicationRecord.transaction do
        next_output_fee_statement.statement_items.create_or_find_by!(
          declaration:,
          state: declaration.state,
        )
      end

      true
    end

  private

    def next_output_fee_statement
      return unless declaration

      @next_output_fee_statement ||= declaration.lead_provider.next_output_fee_statement(declaration.cohort)
    end

    def next_output_fee_statement_exists
      return unless declaration

      errors.add(:declaration, :no_output_fee_statement, cohort: declaration.cohort.start_year) unless next_output_fee_statement
    end

    def declaration_has_attachable_state
      return unless declaration

      errors.add(:declaration, :not_in_attachable_state) if declaration.submitted_state?
    end
  end
end
