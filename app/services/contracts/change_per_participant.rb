# frozen_string_literal: true

module Contracts
  class ChangePerParticipant
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :statement
    attribute :contract
    attribute :per_participant

    after_validation :round_per_participant

    validates :per_participant, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :statement, presence: true
    validates :contract, presence: true
    validate :contract_belongs_to_statement, if: -> { contract.present? }
    validate :statement_not_paid, if: -> { statement.present? }

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

  private

    def contract_belongs_to_statement
      return if contract.statement == statement

      errors.add(:contract, :does_not_belong_to_statement)
    end

    def statement_not_paid
      return unless current_and_future_statements.any?(&:paid?)

      errors.add(:statement, :paid)
    end

    def current_and_future_statements
      (Time.zone.today..Date.new(last_statement.year, last_statement.month)).map { |d| [d.year, d.month] }.uniq.map { |year, month|
        Statement.find_by(year:, month:, cohort: statement.cohort, lead_provider: statement.lead_provider)
      }.compact
    end

    def last_statement
      Statement.where(cohort: statement.cohort, lead_provider: statement.lead_provider).order(:year, :month).last
    end

    def round_per_participant
      self.per_participant = per_participant.to_f.round(2)
    end
  end
end
