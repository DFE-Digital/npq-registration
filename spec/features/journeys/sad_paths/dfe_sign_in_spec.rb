require "rails_helper"

RSpec.feature "DfE sign in", type: :feature do
  include Helpers::JourneyAssertionHelper

  let(:user) { User.find_by(email: "user@example.com") }

  context "when there is an existing user with no DfE Identity UID" do
    include_context "Stub Get An Identity Omniauth Responses"

    before { create(:user, email: "user@example.com", full_name: "previous name") }

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

  context "when there is another account that matches the DfE Identity email but it doesn't have a DfE Identity UID" do
    include_context "Stub Get An Identity Omniauth Responses" do
      let(:user_email) { "user@example.com" }
      let(:user_uid) { other_account_with_dfe_id.uid }
    end

    let!(:user_without_dfe_id) do
      create(:user, email: "user@example.com")
    end
    let!(:other_account_with_dfe_id) { create(:user, :with_get_an_identity_id, email: "old@example.com", full_name: "old name") }

    scenario "starting the journey" do
      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        page.click_button("Start now")
      end

      expect(page).to have_current_path("/registration/start") # current erroneous behaviour

      # temporary fix - archive account that doesn't have UID
      Users::Archiver.new(user: user_without_dfe_id).archive!

      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        page.click_button("Start now")
      end
      expect_page_to_have(path: "/registration/course-start-date", submit_form: true)
      expect(other_account_with_dfe_id.reload.email).to eq "user@example.com"
      expect(other_account_with_dfe_id.full_name).to eq "John Doe"
    end
  end
end
