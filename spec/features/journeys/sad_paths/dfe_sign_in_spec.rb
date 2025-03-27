require "rails_helper"

RSpec.feature "DfE sign in", type: :feature do
  include Helpers::JourneyAssertionHelper

  let(:user) { User.find_by(email: "user@example.com") }

  context "when there is an existing user with the provided DfE Identity UID" do
    let(:existing_user_with_dfe_id) { create(:user, :with_get_an_identity_id, email: "old@example.com", full_name: "old name") }
    let!(:application_for_user_with_dfe_id) { create(:application, :accepted, user: existing_user_with_dfe_id, course: create(:course, :leading_teaching)) }

    context "and the email in DfE Identity has changed" do
      include_context "Stub Get An Identity Omniauth Responses" do
        let(:user_email) { "user@example.com" }
        let(:user_uid) { existing_user_with_dfe_id.uid }
      end

      scenario "the user should be updated with new email from DfE Identity" do
        navigate_to_page(path: "/", submit_form: false, axe_check: false) do
          page.click_button("Start now")
        end

        expect(page).to have_current_path("/accounts/user_registrations/#{application_for_user_with_dfe_id.id}")
        expect(existing_user_with_dfe_id.reload.email).to eq "user@example.com"
      end
    end

    context "and the email in DfE Identity has not changed" do
      include_context "Stub Get An Identity Omniauth Responses" do
        let(:user_email) { "old@example.com" }
        let(:user_uid) { existing_user_with_dfe_id.uid }
      end

      scenario "the user should log in successfully" do
        navigate_to_page(path: "/", submit_form: false, axe_check: false) do
          page.click_button("Start now")
        end

        expect(page).to have_current_path("/accounts/user_registrations/#{application_for_user_with_dfe_id.id}")
        expect(existing_user_with_dfe_id.reload.email).to eq "old@example.com"
      end
    end

    context "and there is another account that matches the DfE Identity email but it doesn't have a DfE Identity UID" do
      include_context "Stub Get An Identity Omniauth Responses" do
        let(:user_email) { "user@example.com" }
        let(:user_uid) { existing_user_with_dfe_id.uid }
      end

      let(:user_without_dfe_id) { create(:user, email: "user@example.com") }
      let!(:application_for_user_without_dfe_id) { create(:application, :accepted, user: user_without_dfe_id, course: create(:course, :leading_teaching)) }

      scenario "the clashing user account should be archived" do
        navigate_to_page(path: "/", submit_form: false, axe_check: false) do
          page.click_button("Start now")
        end

        expect(page).to have_current_path("/account")

        expect(user_without_dfe_id.reload.email).to eq "archived-user@example.com"
        expect(user_without_dfe_id.uid).to be_nil
        expect(user_without_dfe_id.provider).to be_nil
        expect(user_without_dfe_id.archived?).to be true
        expect(user_without_dfe_id.applications.count).to be_zero

        expect(existing_user_with_dfe_id.reload.email).to eq "user@example.com"
        expect(existing_user_with_dfe_id.full_name).to eq "John Doe"
        expect(existing_user_with_dfe_id.applications.to_a).to contain_exactly(application_for_user_with_dfe_id, application_for_user_without_dfe_id)
        expect(existing_user_with_dfe_id.participant_id_changes.last).to have_attributes(from_participant_id: user_without_dfe_id.ecf_id, to_participant_id: existing_user_with_dfe_id.ecf_id)
      end
    end

    context "and there is another account that matches the DfE Identity email that has a different DfE Identity UID" do
      include_context "Stub Get An Identity Omniauth Responses" do
        let(:user_email) { "user@example.com" }
        let(:user_uid) { existing_user_with_dfe_id.uid }
      end

      let(:user_with_same_email_different_dfe_uid) do
        create(:user, :with_get_an_identity_id, email: "user@example.com", full_name: "old name")
      end
      let!(:application_for_user_with_same_email_different_dfe_uid) { create(:application, :accepted, user: user_with_same_email_different_dfe_uid, course: create(:course, :leading_teaching)) }
      let!(:existing_user_with_dfe_id) { create(:user, :with_get_an_identity_id, full_name: "old name", email: "old@example.com", provider: "tra_openid_connect") }

      scenario "the clashing user account should be archived" do
        navigate_to_page(path: "/", submit_form: false, axe_check: false) do
          page.click_button("Start now")
        end

        expect(page).to have_current_path("/account")

        expect(user_with_same_email_different_dfe_uid.reload.email).to eq "archived-user@example.com"
        expect(user_with_same_email_different_dfe_uid.uid).to be_nil
        expect(user_with_same_email_different_dfe_uid.provider).to be_nil
        expect(user_with_same_email_different_dfe_uid.archived?).to be true
        expect(user_with_same_email_different_dfe_uid.applications.count).to be_zero

        expect(existing_user_with_dfe_id.reload.full_name).to eq "John Doe"
        expect(existing_user_with_dfe_id.applications.to_a).to contain_exactly(application_for_user_with_dfe_id, application_for_user_with_same_email_different_dfe_uid)
        expect(existing_user_with_dfe_id.participant_id_changes.last).to have_attributes(from_participant_id: user_with_same_email_different_dfe_uid.ecf_id, to_participant_id: existing_user_with_dfe_id.ecf_id)
      end
    end

    context "and the account is archived and there is a non-archived account with the same email" do
      let!(:existing_user_with_dfe_id) { create(:user, :archived, :with_get_an_identity_id, email: "archived-user@example.com") }
      let!(:application_for_user) { create(:application, :accepted, user: user, course: create(:course, :leading_teaching)) }
      let(:user) { create(:user, email: "user@example.com") }

      include_context "Stub Get An Identity Omniauth Responses" do
        let(:user_email) { "user@example.com" }
        let(:user_uid) { existing_user_with_dfe_id.uid }
      end

      scenario "the archived account should have its UID blanked, and the non-archived account should be updated with the UID" do
        navigate_to_page(path: "/", submit_form: false, axe_check: false) do
          page.click_button("Start now")
        end

        expect(page).to have_current_path("/accounts/user_registrations/#{application_for_user.id}")
        expect(user.reload.uid).to eq existing_user_with_dfe_id.uid
      end
    end
  end

  context "when there is no user with the provided DfE Identity UID" do
    context "and there is an existing user with the provided email" do
      context "and the existing user has no DfE Identity UID" do
        let(:existing_user) { create(:user, email: "user@example.com") }
        let!(:application_for_existing_user) { create(:application, :accepted, user: existing_user, course: create(:course, :leading_teaching)) }
        let(:uid) { SecureRandom.uuid }

        include_context "Stub Get An Identity Omniauth Responses" do
          let(:user_email) { "user@example.com" }
          let(:user_uid) { uid }
        end

        scenario "the user account should be updated with the UID" do
          navigate_to_page(path: "/", submit_form: false, axe_check: false) do
            page.click_button("Start now")
          end

          expect(page).to have_current_path("/accounts/user_registrations/#{application_for_existing_user.id}")
          expect(existing_user.reload.uid).to eq uid
          expect(existing_user.provider).to eq "tra_openid_connect"
          expect(existing_user.full_name).to eq "John Doe"
          expect(existing_user.applications.first).to eq application_for_existing_user
        end
      end

      context "and the clashing user has a different DfE Identity UID" do # TODO: implement this
        let(:clashing_user) { create(:user, :with_get_an_identity_id, email: "user@example.com") }
        let!(:application_for_clashing_user) { create(:application, :accepted, user: clashing_user, course: create(:course, :leading_teaching)) }
        let(:uid) { SecureRandom.uuid }

        include_context "Stub Get An Identity Omniauth Responses" do
          let(:user_email) { "user@example.com" }
          let(:user_uid) { uid }
        end

        scenario "the clashing user account be updated with the new UID" do # or should it be archived, and a new user created? (way more complex to implement)
          navigate_to_page(path: "/", submit_form: false, axe_check: false) do
            page.click_button("Start now")
          end

          expect(page).to have_current_path("/accounts/user_registrations/#{application_for_clashing_user.id}")

          expect(clashing_user.reload.email).to eq "user@example.com"
          expect(clashing_user.uid).to eq uid
          expect(clashing_user.provider).to eq "tra_openid_connect"
          expect(clashing_user.archived?).to be false
          expect(clashing_user.applications.first).to eq application_for_clashing_user
        end
      end
    end

    context "when there is no existing user with the provided email" do
      let(:uid) { SecureRandom.uuid }
      let(:new_user_created_with_uid) { User.find_by(uid: uid) }

      include_context "Stub Get An Identity Omniauth Responses" do
        let(:user_email) { "user@example.com" }
        let(:user_uid) { uid }
      end

      scenario "a new user account should be created with the UID and email" do
        navigate_to_page(path: "/", submit_form: false, axe_check: false) do
          page.click_button("Start now")
        end

        expect(page).to have_current_path("/registration/course-start-date")
        expect(new_user_created_with_uid.email).to eq "user@example.com"
        expect(new_user_created_with_uid.provider).to eq "tra_openid_connect"
        expect(new_user_created_with_uid.full_name).to eq "John Doe"
      end
    end
  end
end
