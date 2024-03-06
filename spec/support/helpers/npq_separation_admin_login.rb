module Helpers
  module NPQSeparationAdminLogin
    def sign_in_as_admin(email: "test-admin@example.com", super_admin: false)
      FactoryBot.create(:admin, email:, super_admin:).then do |u|
        patch(session_wizard_update_path(step: "sign-in"), params: { session_wizard: { email: } })
        patch(session_wizard_update_path(step: "sign-in-code"), params: { session_wizard: { code: u.reload.otp_hash } })
      end
    end
  end
end
