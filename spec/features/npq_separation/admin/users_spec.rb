require "rails_helper"

RSpec.feature "User administration", type: :feature do
  include Helpers::AdminLogin

  let(:users_per_page) { Pagy::DEFAULT[:limit] }
  let(:user) { User.first }

  before do
    create_list(:user, users_per_page, :with_get_an_identity_id)
    sign_in_as(create(:admin))
  end

  feature "listing users" do
    scenario "viewing the list of users" do
      visit(npq_separation_admin_users_path)

      expect(page).to have_css("h1", text: "All participants")

      User.all.find_each do |user|
        expect(page).to have_link(user.full_name, href: npq_separation_admin_user_path(user))
        expect(page).to have_css("td", text: user.trn)
        expect(page).to have_css("td", text: user.created_at.to_date.to_formatted_s(:govuk))
      end
    end

    scenario "navigating to the second page of users" do
      create :user, :with_get_an_identity_id # exceed pagination threshold

      visit(npq_separation_admin_users_path)

      click_on("Next")

      expect(page).to have_css("table.govuk-table tbody tr", count: 1)
      expect(page).to have_css(".govuk-pagination__item--current", text: "2")
    end

    scenario "searching for a user" do
      visit(npq_separation_admin_users_path)

      fill_in("Search records", with: user.email)
      click_on("Search")

      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to have_css("tbody tr", text: user.full_name)
    end
  end

  feature "viewing a user" do
    scenario "shows user details" do
      visit npq_separation_admin_user_path(user)

      expect(page).to have_css("h1", text: "Participant")

      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("ID", user.id)
        expect(summary_list).to have_summary_item("ECF ID", user.ecf_id)
        expect(summary_list).to have_summary_item("Email", user.email)
        expect(summary_list).to have_summary_item("Name", user.full_name)
        expect(summary_list).to have_summary_item("TRN", user.trn)
        expect(summary_list).to have_summary_item("TRN validated", "No")
        expect(summary_list).to have_summary_item("Get an Identity ID", user.get_an_identity_id)
      end
    end

    scenario "renders when attributes with method chains are nil" do
      user.update!(date_of_birth: nil)
      visit npq_separation_admin_user_path(user)

      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("Date of Birth", "")
      end
    end

    scenario "shows a message if the user has no applications" do
      visit npq_separation_admin_user_path(user)

      expect(page).to have_css("h1", text: "Applications")
      expect(page).to have_css(".govuk-body", text: "This participant has no applications.")
    end

    scenario "shows a summary of each user application" do
      applications = %i[headship senco].map { create(:application, user:, course: create(:course, _1)) }
      visit npq_separation_admin_user_path(user)

      expect(page).to have_css("h1", text: "Applications")
      applications.each.with_index(1) do |application, index|
        within(".govuk-summary-card", text: "Application #{index}") do |summary_card|
          expect(summary_card).to have_link("View full application", href: npq_separation_admin_application_path(application))
          expect(summary_card).to have_summary_item("Application ID", application.id)
          expect(summary_card).to have_summary_item("Lead Provider", application.lead_provider.name)
          expect(summary_card).to have_summary_item("Lead Provider Approval Status", application.lead_provider_approval_status)
          expect(summary_card).to have_summary_item("NPQ Course", application.course.name)
          expect(summary_card).to have_summary_item("School URN", application.school.urn)
          expect(summary_card).to have_summary_item("School UKPRN", application.school.ukprn)
          expect(summary_card).to have_summary_item("Funded Place", "")
          expect(summary_card).to have_summary_item("Created At", application.created_at.to_fs(:govuk_short))
          expect(summary_card).to have_summary_item("Updated At", application.updated_at.to_fs(:govuk_short))
        end
      end
    end

    scenario "changing a user's TRN" do
      visit npq_separation_admin_user_path(user)
      click_link "Change"

      expect(page).to have_css("h1", text: "Change TRN")
      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("Participant ID", user.ecf_id)
        expect(summary_list).to have_summary_item("TRN", user.trn)
      end
      fill_in("New TRN", with: "2345678")
      click_on("Continue")

      expect(page).to have_css("h1", text: "Participant")
      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("TRN", "2345678")
      end
      expect(user.reload.trn).to eq "2345678"
    end
  end
end
