# frozen_string_literal: true

module Users
  class SetRefreshToken
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user
    attribute :refresh_token, :string

    def self.call(user:, refresh_token:)
      new(user:, refresh_token:).call
    end

    def call
      if user.trn.blank? && refresh_token.present?
        token_record = user.oauth_token || user.oauth_tokens.build(token_type: :refresh_token)
        token_record.update!(token: refresh_token, token_updated_at: Time.current)
        true
      elsif user.trn.present? && user.oauth_token.present?
        user.oauth_token.destroy!
        false
      else
        false
      end
    end
  end
end
