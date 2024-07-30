# frozen_string_literal: true

module Declarations
  class Void
    include ActiveModel::Model
    include ActiveModel::Attributes

    CLAWBACK_STATES = %w[paid awaiting_clawback clawed_back].freeze

    attribute :declaration

    validates :declaration, presence: true

    validate :declaration_not_already_voided, if: :voiding?

    validate :declaration_not_already_refunded, if: :clawing_back?
    validate :output_fee_statement_available, if: :clawing_back?
    validate :declaration_is_paid, if: :clawing_back?

    def void
      return false unless valid?

      ApplicationRecord.transaction do
        clawing_back? ? clawback_declaration : void_declaration

        void_participant_outcome
      end

      true
    end

  private

    def clawback_declaration
      declaration.awaiting_clawback_state!
      statement_attacher.attach
    end

    def void_declaration
      declaration.voided_state!
      declaration.statement_items.with_state(:eligible, :payable).first&.mark_voided!
    end

    def declaration_not_already_voided
      return unless declaration

      errors.add(:declaration, :already_voided) if declaration.voided_state?
    end

    def declaration_not_already_refunded
      return unless declaration

      already_refunded = declaration.statement_items.refundable.exists?
      errors.add(:declaration, :not_already_refunded) if already_refunded
    end

    def output_fee_statement_available
      errors.add(:declaration, :no_output_fee_statement, cohort: declaration.cohort.start_year) unless statement_attacher.valid?
    end

    def declaration_is_paid
      return if errors[:declaration].any?

      errors.add(:declaration, :must_be_paid) unless declaration&.paid_state?
    end

    def statement_attacher
      @statement_attacher ||= StatementAttacher.new(declaration:)
    end

    def clawing_back?
      declaration&.state.in?(CLAWBACK_STATES)
    end

    def voiding?
      !clawing_back?
    end

    def void_participant_outcome
      ParticipantOutcomes::Void.new(declaration:).void_outcome
    end
  end
end
