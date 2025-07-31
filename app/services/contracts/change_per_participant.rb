# frozen_string_literal: true

module Contracts
  class ChangePerParticipant
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :contract
    attribute :per_participant

    after_validation :round_per_participant

    validates :per_participant, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :contract, presence: true
    validate :statement_not_paid, if: -> { contract&.statement.present? }

    def change
      return false if invalid?

      ActiveRecord::Base.transaction do
        current_and_future_statements.each do |statement_for_month|
          contract_for_month = statement_for_month.contracts.find_by(course: contract.course)
          contract_template = contract_for_month.contract_template.find_from_existing(per_participant:) || contract_for_month.contract_template.new_from_existing(per_participant:)
          contract_for_month.update!(contract_template:)
        end
      end

      true
    end

    def start_date
      @start_date ||= Time.zone.today
    end

    def end_date
      @end_date ||= Date.new(last_statement.year, last_statement.month)
    end

  private

    def statement_not_paid
      return unless current_and_future_statements.any?(&:paid?)

      errors.add(:contract, :statement_paid)
    end

    def current_and_future_statements
      periods_for_current_and_future_statements = (start_date..end_date).map { |d| [d.year, d.month] }
      Statement
        .where(cohort: contract.statement.cohort, lead_provider: contract.statement.lead_provider)
        .to_a
        .select { |s| periods_for_current_and_future_statements.include? [s.year, s.month] }
    end

    def last_statement
      Statement.where(cohort: contract.statement.cohort, lead_provider: contract.statement.lead_provider).order(:year, :month).last
    end

    def round_per_participant
      self.per_participant = per_participant.to_f.round(2)
    end
  end
end
