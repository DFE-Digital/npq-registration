# frozen_string_literal: true

module Statements
  class ChangeOutputFee
    include ActiveModel::Model
    include ActiveModel::Attributes
    include StatementHelper

    attribute :statement
    attribute :output_fee, :boolean
    attribute :allow_payable_statement_changes, :boolean, default: false

    validates :statement, presence: true, validate_and_copy_errors: true
    validates :output_fee, inclusion: [true, false]
    validates :allow_payable_statement_changes, acceptance: true, if: -> { statement&.payable? }
    validate :statement_is_not_paid, if: :statement
    validate :next_output_statement_exists
    validate :payment_date_has_passed

    class << self
      def can_change_statement?(statement)
        if statement.payable?
          statement.output_fee || statement.payment_date > Time.zone.today
        else
          statement.open?
        end
      end
    end

    def statement=(...)
      super.tap do
        if statement && output_fee.nil?
          self.output_fee = statement.output_fee
        end
      end
    end

    def requires_payable_override?
      statement&.payable?
    end

    def schedule_change
      statement.output_fee = output_fee
      return false if invalid?
      return false unless statement.output_fee_changed?

      ChangeOutputFeeJob.perform_later(statement_id: statement.id,
                                       output_fee:,
                                       allow_payable_statement_changes:)

      true
    end

    def change_statement_and_reconcile!
      Statement.transaction do
        Statement.with_advisory_lock!("lock-statement-#{statement.cohort.identifier}-lead-provider-#{statement.lead_provider_id}") do
          return if statement.output_fee == output_fee

          validate!

          if output_fee
            statement.update!(output_fee:)
            move_milestones_onto_this_statement
            move_declarations_onto_this_statement
          else
            move_milestones_off_this_statement
            move_declarations_off_this_statement
            statement.update!(output_fee:)
          end
        end
      end
    end

    def move_onto_hint
      return if statement.output_fee_was

      if next_output_statement
        milestone_count = next_output_statement.milestones.count
        declaration_count = next_output_statement
          .declarations
          .where(declaration_date: ..statement.deadline_date)
          .count

        "This will move #{declaration_count} declarations and #{milestone_count} milestones from the next output statement, #{statement_name(next_output_statement)}, onto this statement"
      else
        "There is no later output statement and no declarations or milestones will be moved"
      end
    end

    def move_off_hint
      return unless statement.output_fee_was

      if statement.declarations.empty? && statement.milestones.empty?
        "There are no declarations or milestones on this statement"
      elsif next_output_statement
        statement_state = statement.payable? ? "Unpaid" : "Open"
        "This will move #{statement.declarations.count} declarations and #{statement.milestones.count} milestones from this statement to the next #{statement_state} output statement which is #{statement_name(next_output_statement)}"
      else
        "There are #{statement.declarations.count} declarations and #{statement.milestones.count} milestones on this statement but no suitable later statement"
      end
    end

    def next_output_statement
      @next_output_statement ||= statement
        .lead_provider
        .statements
        .with_output_fee
        .merge(statement.payable? ? Statement.unpaid : Statement.open)
        .order(:deadline_date)
        .where(deadline_date: (statement.deadline_date + 1.day)..)
        .where(payment_date: Time.zone.tomorrow..)
        .where(cohort: statement.cohort)
        .first
    end

  private

    def statement_is_not_paid
      if statement&.paid?
        errors.add :output_fee, :statement_is_paid
      end
    end

    def next_output_statement_exists
      return if output_fee
      return if next_output_statement
      return unless statement
      return if statement.declarations.count.zero? && statement.milestones.count.zero?

      errors.add :output_fee, :next_output_statement_required
    end

    def payment_date_has_passed
      return unless statement
      return if statement.output_fee
      return if statement.payment_date > Time.zone.today

      errors.add :output_fee, :payment_date_has_passed
    end

    def move_declarations_onto_this_statement
      if next_output_statement
        move_declarations(next_output_statement, statement)
      end
    end

    def move_declarations_off_this_statement
      move_declarations(statement, next_output_statement)
    end

    def move_declarations(from_statement, to_statement)
      from_statement
        .statement_items
        .includes(:declaration)
        .find_each do |statement_item|
          next unless statement_item.declaration.declaration_date <= to_statement.deadline_date

          statement_item.update!(statement: to_statement)

          if to_statement.payable? && statement_item.declaration.eligible?
            statement_item.declaration.mark_payable!
            statement_item.mark_payable!
          elsif to_statement.open? && statement_item.declaration.payable?
            statement_item.declaration.revert_to_eligible!
            statement_item.revert_to_eligible!
          end
        end
    end

    def move_milestones_onto_this_statement
      if next_output_statement
        move_milestones(next_output_statement, statement)
      end
    end

    def move_milestones_off_this_statement
      move_milestones(statement, next_output_statement)
    end

    def move_milestones(from_statement, to_statement)
      from_statement
        .milestone_statements
        .find_each do |milestone_statement|
          milestone_statement.update!(statement: to_statement,
                                      skip_statement_date_validation: true)
        end
    end
  end
end
