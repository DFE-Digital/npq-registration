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

    def change
      return false if invalid?

      contract_template = contract.contract_template.find_from_existing(per_participant:) || contract.contract_template.new_from_existing(per_participant:)
      contract.update(contract_template:) # rubocop:disable Rails/SaveBang - return value is used by caller
    end

  private

    def round_per_participant
      self.per_participant = per_participant.to_f.round(2)
    end
  end
end
