module TeachingRecordSystem
  class AllocateTrnJob < ApplicationJob
    def perform(user_id:)
      user = User.find(user_id)

      if user.trn.present?
        # TRN has been allocated already and token no longer needed
        user.refresh_token.destroy!
        return
      end

      new_access, new_refresh = RefreshTokens.refresh!(user.refresh_token.token)
      user.refresh_token.store!(new_refresh)

      new_trn = ActivateTrnRequest.activate!(new_access)
      if new_trn.present?
        # Received TRN from API response so don't need to wait for webhook to receive TRN
        user.update!(trn: new_trn, trn_verified: true, trn_auto_verified: true)
      end

      user.refresh_token.destroy!
    end
  end
end
