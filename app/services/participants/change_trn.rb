# frozen_string_literal: true

module Participants
  class ChangeTrn
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :user
    attribute :trn

    before_validation :strip_trn_whitespace

    validates :user, presence: true
    validates :trn, valid_trn: true
    validate :trn_not_managed_from_trs, if: :user

    def change_trn
      return false if invalid?

      user.update(trn:, trn_verified: true, trn_lookup_status: nil) # rubocop:disable Rails/SaveBang - return value is used by caller
    end

  private

    def strip_trn_whitespace
      self.trn = trn&.gsub(" ", "")
    end

    def trn_not_managed_from_trs
      return unless user.teacher_auth_provider?

      errors.add :user, :assign_trn_from_trs
    end
  end
end
