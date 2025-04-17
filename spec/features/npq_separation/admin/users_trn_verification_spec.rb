require "rails_helper"

RSpec.feature "viewing a user's TRN status", type: :feature do
  include Helpers::AdminLogin

  feature "when TRN verified is true and TRN auto verified is true" do
    scenario "shows TRN verified automatically" do
      user = create(:user, trn_verified: true, trn_auto_verified: true)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("TRN status", "TRN verified - automatically")
      end
    end
  end

  feature "when TRN verified is true and TRN auto verified is false" do
    scenario "shows TRN verified manually" do
      user = create(:user, trn_verified: true, trn_auto_verified: false)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("TRN status", "TRN verified - manually")
      end
    end
  end

  feature "when TRN verified is false and TRN auto verified is true" do
    scenario "shows TRN verified automatically" do
      user = create(:user, trn_verified: false, trn_auto_verified: true)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("TRN status", "TRN verified - automatically")
      end
    end
  end

  feature "when TRN verified is false and TRN auto verified is false" do
    scenario "shows TRN not verified" do
      user = create(:user, trn_verified: false, trn_auto_verified: false)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("TRN status", "TRN not verified")
      end
    end
  end
end
