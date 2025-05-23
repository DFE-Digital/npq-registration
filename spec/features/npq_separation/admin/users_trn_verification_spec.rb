require "rails_helper"

RSpec.feature "viewing a user's TRN status", type: :feature do
  include Helpers::AdminLogin

  feature "when TRN verified is true and TRN auto verified is true" do
    scenario "shows TRN: verified automatically" do
      user = create(:user, trn_verified: true, trn_auto_verified: true)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      expect(page).to have_content("TRN: #{user.trn} Verified - automatically")
    end
  end

  feature "when TRN verified is true and TRN auto verified is false" do
    scenario "shows TRN verified manually" do
      user = create(:user, trn_verified: true, trn_auto_verified: false)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      expect(page).to have_content("TRN: #{user.trn} Verified - manually")
    end
  end

  feature "when TRN verified is false and TRN auto verified is true" do
    scenario "shows TRN not verified" do
      user = create(:user, trn_verified: false, trn_auto_verified: true)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      expect(page).to have_content("TRN: #{user.trn} Not verified")
    end
  end

  feature "when TRN verified is false and TRN auto verified is false" do
    scenario "shows TRN not verified" do
      user = create(:user, trn_verified: false, trn_auto_verified: false)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      expect(page).to have_content("TRN: #{user.trn} Not verified")
    end
  end
end
