require "rails_helper"

RSpec.feature "Admin Duplicate Users page", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }

  let(:archived_user_with_no_matched_user) { create(:user, :archived, email: nil) }

  let(:archived_user_with_matched_user_and_trn_but_no_applications) { create(:user, :archived, :with_verified_trn, email: nil) }
  let(:matched_user_with_trn) { create(:user, :with_verified_trn, email: archived_user_with_matched_user_and_trn_but_no_applications.archived_email) }

  let(:archived_user_with_matched_user_and_trn) { create(:user, :archived, :with_verified_trn, email: nil) }
  let(:matched_user_with_trn_2) { create(:user, :with_verified_trn, email: archived_user_with_matched_user_and_trn.archived_email) }

  let(:archived_user_with_matched_user_and_unverified_trn) { create(:user, :archived, email: nil) }
  let(:matched_user_with_unverifed_trn) { create(:user, email: archived_user_with_matched_user_and_unverified_trn.archived_email) }

  let(:archived_user_with_matched_user_and_no_trn) { create(:user, :archived, email: nil, trn: nil) }
  let(:matched_user_with_no_trn) { create(:user, trn: nil, email: archived_user_with_matched_user_and_no_trn.archived_email) }

  let(:archived_user_with_matched_user_and_rejected_application) { create(:user, :archived, email: nil) }
  let(:matched_user_with_trn_3) { create(:user, :with_verified_trn, email: archived_user_with_matched_user_and_rejected_application.archived_email) }

  before do
    create(:application, user: archived_user_with_no_matched_user)
    create(:application, user: archived_user_with_matched_user_and_trn)
    create(:application, user: archived_user_with_matched_user_and_unverified_trn)
    create(:application, user: archived_user_with_matched_user_and_no_trn)
    create(:application, :rejected, user: archived_user_with_matched_user_and_rejected_application)
    matched_user_with_trn
    matched_user_with_trn_2
    matched_user_with_trn_3
    matched_user_with_unverifed_trn
    matched_user_with_no_trn
  end

  context "when not logged in" do
    scenario "duplicate users page is inaccessible" do
      visit admin_duplicate_users_path
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as_admin }

    scenario "it displays the duplicate users page" do
      page.click_link "Users"
      page.click_link "Archived duplicate users"

      expect(page).to have_content("Archived duplicate users")

      expect(page).to have_content(archived_user_with_no_matched_user.full_name)
      expect(page).to have_content(archived_user_with_no_matched_user.archived_email)

      expect(page).not_to have_content(archived_user_with_matched_user_and_trn_but_no_applications.full_name)

      expect(page).not_to have_content(archived_user_with_matched_user_and_rejected_application.full_name)

      expect(page).to have_content(archived_user_with_matched_user_and_trn.full_name)
      expect(page).to have_content(archived_user_with_matched_user_and_trn.archived_email)
      expect(page).to have_content(archived_user_with_matched_user_and_trn.trn)
      expect(page).to have_link("#{matched_user_with_trn_2.full_name} (#{matched_user_with_trn_2.trn})", href: admin_user_path(matched_user_with_trn_2))

      expect(page).to have_content(archived_user_with_matched_user_and_unverified_trn.full_name)
      expect(page).to have_content(archived_user_with_matched_user_and_unverified_trn.archived_email)
      expect(page).not_to have_content(archived_user_with_matched_user_and_unverified_trn.trn)
      expect(page).to have_link(matched_user_with_unverifed_trn.full_name, href: admin_user_path(matched_user_with_unverifed_trn))
      expect(page).not_to have_content(matched_user_with_unverifed_trn.trn)

      expect(page).to have_content(archived_user_with_matched_user_and_no_trn.full_name)
      expect(page).to have_content(archived_user_with_matched_user_and_no_trn.archived_email)
      expect(page).to have_link(matched_user_with_no_trn.full_name, href: admin_user_path(matched_user_with_no_trn))
      expect(page).not_to have_content("()")
    end
  end
end
