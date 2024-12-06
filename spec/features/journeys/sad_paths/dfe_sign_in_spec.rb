require "rails_helper"

RSpec.feature "DfE sign in", :ecf_api_disabled, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper

  let(:user) { User.find_by(email: "user@example.com") }

  context "when there is an existing user with no DfE Identity UID" do
    include_context "Stub Get An Identity Omniauth Responses"

    before { create(:user, email: "user@example.com", full_name: "old name") }

    scenario "the user should be updated with DfE Identity attributes" do
      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        page.click_button("Start now")
      end

      expect_page_to_have(path: "/registration/course-start-date", submit_form: true)
      expect(user.uid).to be_present
      expect(user.provider).to eq "tra_openid_connect"
      expect(user.full_name).to eq "John Doe"
    end
  end

  context "when there is an existing user with DfE Identity UID, and the email in DfE Identity has changed" do
    include_context "Stub Get An Identity Omniauth Responses" do
      let(:user_email) { "user@example.com" }
      let(:user_uid) { user_with_dfe_id.uid }
    end

    let!(:user_with_dfe_id) { create(:user, :with_get_an_identity_id, email: "old@example.com", full_name: "old name") }

    scenario "the user should be updated with new email from DfE Identity" do
      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        page.click_button("Start now")
      end

      expect_page_to_have(path: "/registration/course-start-date", submit_form: true)
      expect(user_with_dfe_id.reload.email).to eq "user@example.com"
    end
  end

  context "when there is another account that matches the DfE Identity email but it doesn't have a DfE Identity UID" do
    include_context "Stub Get An Identity Omniauth Responses" do
      let(:user_email) { "user@example.com" }
      let(:user_uid) { user_with_dfe_id.uid }
    end

    let(:user_without_dfe_id) { create(:user, email: "user@example.com") }
    let!(:application_for_user_without_dfe_id) { create(:application, :accepted, user: user_without_dfe_id, course: create(:course, :leading_teaching)) }
    let(:user_with_dfe_id) { create(:user, :with_get_an_identity_id, email: "old@example.com", full_name: "old name", trn: user_without_dfe_id.trn) }

    scenario "clashing user account should be archived" do
      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        page.click_button("Start now")
      end

      expect(page).to have_current_path("/accounts/user_registrations/#{application_for_user_without_dfe_id.id}")

      expect(user_without_dfe_id.reload.email).to eq "archived-user@example.com"
      expect(user_without_dfe_id.uid).to be_nil
      expect(user_without_dfe_id.provider).to be_nil
      expect(user_without_dfe_id.archived?).to be true
      expect(user_without_dfe_id.applications.count).to be_zero

      expect(user_with_dfe_id.reload.email).to eq "user@example.com"
      expect(user_with_dfe_id.full_name).to eq "John Doe"
      expect(user_with_dfe_id.applications.first).to eq application_for_user_without_dfe_id
      expect(user_with_dfe_id.participant_id_changes.last).to have_attributes(from_participant_id: user_without_dfe_id.ecf_id, to_participant_id: user_with_dfe_id.ecf_id)
    end
  end

  context "when there is another account that matches the DfE Identity email that has a different DfE Identity UID" do
    include_context "Stub Get An Identity Omniauth Responses" do
      let(:user_email) { "user@example.com" }
      let(:user_uid) { user_with_dfe_id.uid }
    end

    let(:user_with_same_email_different_dfe_uid) do
      create(:user, :with_get_an_identity_id, email: "user@example.com", full_name: "old name")
    end
    let!(:application_for_user_with_same_email_different_dfe_uid) { create(:application, :accepted, user: user_with_same_email_different_dfe_uid, course: create(:course, :leading_teaching)) }
    let!(:user_with_dfe_id) { create(:user, :with_get_an_identity_id, full_name: "old name", email: "old@example.com", provider: "tra_openid_connect") }

    scenario "clashing user account should be archived" do
      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        page.click_button("Start now")
      end

      expect(page).to have_current_path("/accounts/user_registrations/#{application_for_user_with_same_email_different_dfe_uid.id}")

      expect(user_with_same_email_different_dfe_uid.reload.email).to eq "archived-user@example.com"
      expect(user_with_same_email_different_dfe_uid.uid).to be_nil
      expect(user_with_same_email_different_dfe_uid.provider).to be_nil
      expect(user_with_same_email_different_dfe_uid.archived?).to be true
      expect(user_with_same_email_different_dfe_uid.applications.count).to be_zero

      expect(user_with_dfe_id.reload.full_name).to eq "John Doe"
      expect(user_with_dfe_id.applications.first).to eq application_for_user_with_same_email_different_dfe_uid
      expect(user_with_dfe_id.participant_id_changes.last).to have_attributes(from_participant_id: user_with_same_email_different_dfe_uid.ecf_id, to_participant_id: user_with_dfe_id.ecf_id)
    end
  end
end
