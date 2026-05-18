module TeachingRecordSystem
  class AllocateTrnJob < ApplicationJob
    def perform(user_id:)
      user = User.find(user_id)
      persisted_token = user.oauth_tokens.refresh.first

      if user.trn.present?
        # TRN has been allocated already and token no longer needed
        persisted_token.destroy!
        return
      end

      new_access, new_refresh = RefreshTokens.refresh!(persisted_token.token)
      persisted_token.update!(token: new_refresh, last_updated_token_at: Time.zone.now)

      new_trn = ActivateTrnRequest.activate!(new_access)
      if new_trn.present?
        # Received TRN from API response so don't need to wait for webhook to receive TRN
        user.update!(trn: new_trn, trn_verified: true, trn_auto_verified: true)
      end

      persisted_token.destroy!
    end
  end
end
