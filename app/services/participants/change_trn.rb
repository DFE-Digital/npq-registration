# frozen_string_literal: true

module Participants
  class ChangeTrn
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :user
    attribute :trn

    before_validation :strip_trn_whitespace

    validates :trn, valid_trn: true

    def change_trn
      return false if invalid?

      user.update(trn:) # rubocop:disable Rails/SaveBang - return value is used by caller
    end

  private

    def strip_trn_whitespace
      self.trn = trn&.gsub(" ", "")
    end
  end
end
