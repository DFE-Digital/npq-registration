require "rails_helper"

RSpec.feature "viewing a user's TRN status", :no_js, type: :feature do
  include Helpers::AdminLogin

  feature "when TRN verified is true and TRN auto verified is true" do
    scenario "shows TRN: verified automatically" do
      user = create(:user, trn_verified: true, trn_auto_verified: true)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      within(".govuk-summary-card", text: "Overview") do |summary_card|
        expect(summary_card).to have_summary_item("TRN", "#{user.trn} Verified - automatically")
      end
    end
  end

  feature "when TRN verified is true and TRN auto verified is false" do
    context "when TRN lookup status is Found" do
      scenario "shows TRN verified automatically" do
        user = create(:user, trn_verified: true, trn_auto_verified: false, trn_lookup_status: "Found")
        sign_in_as(create(:admin))
        visit npq_separation_admin_user_path(user)
        within(".govuk-summary-card", text: "Overview") do |summary_card|
          expect(summary_card).to have_summary_item("TRN", "#{user.trn} Verified - automatically")
        end
      end
    end

    context "when TRN lookup status is not Found" do
      scenario "shows TRN verified manually" do
        user = create(:user, trn_verified: true, trn_auto_verified: false, trn_lookup_status: "Pending")
        sign_in_as(create(:admin))
        visit npq_separation_admin_user_path(user)
        within(".govuk-summary-card", text: "Overview") do |summary_card|
          expect(summary_card).to have_summary_item("TRN", "#{user.trn} Verified - manually")
        end
      end
    end
  end

  feature "when TRN verified is false and TRN auto verified is true" do
    scenario "shows TRN not verified" do
      user = create(:user, trn_verified: false, trn_auto_verified: true)
      sign_in_as(create(:admin))
      visit npq_separation_admin_user_path(user)
      within(".govuk-summary-card", text: "Overview") do |summary_card|
        expect(summary_card).to have_summary_item("TRN", "#{user.trn} Not verified")
      end
    end
  end
end
