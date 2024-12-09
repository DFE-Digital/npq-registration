# frozen_string_literal: true

module Participants
  class ChangeTrn
    FORBIDDEN_TRNS = %w[0000000].freeze

    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :user
    attribute :trn

    before_validation :strip_trn_whitespace

    validates :trn, presence: true, length: { is: 7 }
    validates :trn, exclusion: FORBIDDEN_TRNS
    validates :trn, format: { with: /\A\d+\z/ }

    def call
      return false if invalid?

      user.update(trn:) # rubocop:disable Rails/SaveBang - return value is used by caller
    end

  private

    def strip_trn_whitespace
      self.trn = trn&.gsub(" ", "")
    end
  end
end
