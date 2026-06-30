require "rails_helper"

RSpec.feature "User administration", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:users_per_page) { Pagy::DEFAULT[:limit] }
  let(:user) { User.first }
  let(:users) { create_list(:user, users_per_page, :with_get_an_identity_id) }

  before do
    users
    user.update!(national_insurance_number: "QQ123456C", preferred_name: "Jonny D")
    sign_in_as(create(:admin))
  end

  feature "listing users" do
    let(:another_user) { create(:user, :with_teacher_auth, full_name: "Dave J") }

    scenario "viewing the list of users" do
      another_user

      visit(admin_users_path)

      expect(page).to have_css("h1", text: "Users")
      expect(page).to have_css("h2", text: "Recently added")
      expect(page).to have_css("tbody tr:first-of-type td", text: another_user.trn)
      expect(page).to have_css("tbody tr", count: users_per_page)
      expect(page).to have_css("nav.govuk-pagination")

      within("nav.govuk-pagination") do
        click_on("2")
      end

      expect(page).to have_css("h1", text: "Users")
      expect(page).to have_css("h2", text: "Recently added")
      expect(page).to have_css("tbody tr", count: 1)
    end

    scenario "searching for users" do
      visit(admin_users_path)

      fill_in("Find a user", with: "J")
      click_on("Search")
      expect(page).to have_css(".govuk-inset-text", text: "at least 2")

      fill_in("Find a user", with: "Jo")
      click_on("Search")
      expect(page).to have_css("h2", text: "Search results")
      expect(page).to have_css("tbody tr", count: users_per_page)

      User.find_each do |user|
        expect(page).to have_link(user.full_name, href: admin_user_path(user))
        expect(page).to have_css("td", text: user.trn)
        expect(page).to have_css("td", text: user.created_at.to_date.to_formatted_s(:govuk))
      end
    end

    scenario "navigating to the second page of search results" do
      create :user, :with_get_an_identity_id # exceed pagination threshold

      visit(admin_users_path)

      fill_in("Find a user", with: "John")
      click_on("Search")

      click_on("Next")

      expect(page).to have_css("table.govuk-table tbody tr", count: 1)
      expect(page).to have_css(".govuk-pagination__item--current", text: "2")
    end

    scenario "searching for a user" do
      visit(admin_users_path)

      fill_in("Find a user", with: user.email)
      click_on("Search")

      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to have_css("tbody tr", text: user.full_name)
    end

    scenario "searching with no input shows a message" do
      visit(admin_users_path)

      click_on("Search")

      expect(page).to have_css(".govuk-inset-text", text: "Please enter at least 2 characters to search and see results.")
      expect(page).not_to have_css("table.govuk-table")
    end

    scenario "searching with 1 character shows a message" do
      visit(admin_users_path)

      fill_in("Find a user", with: "a")
      click_on("Search")

      expect(page).to have_css(".govuk-inset-text", text: "Please enter at least 2 characters to search and see results.")
      expect(page).not_to have_css("table.govuk-table")
    end
  end

  feature "viewing a user" do
    scenario "shows user details" do
      visit admin_user_path(user)

      expect(page).to have_css("h1", text: user.full_name)

      within(".govuk-summary-card", text: "Overview") do |summary_card|
        expect(summary_card).to have_summary_item("User ID", user.ecf_id)
        expect(summary_card).to have_summary_item("Preferred name", user.preferred_name)
        expect(summary_card).to have_summary_item("Email", user.email)
        expect(summary_card).to have_summary_item("TRN", user.trn, "Not verified")
        expect(page).to have_link("View teaching record", href: "#{ENV['TRS_URL']}/persons?Search=#{user.trn}")
        expect(summary_card).to have_summary_item("Login provider", user.provider)
        expect(summary_card).to have_summary_item("UID", user.uid)
      end
    end

    scenario "shows a message if the user has no applications" do
      visit admin_user_path(user)

      expect(page).to have_css("h1", text: user.full_name)
      expect(page).to have_css(".govuk-body", text: "This user has no applications.")
    end

    scenario "shows a summary of each user application" do
      applications = %i[headship senco]
        .map { create(:application, user:, course: create(:course, _1)) }
        .sort_by { [_1.created_at, _1.id] }

      applications.each do |a|
        create(:declaration, :completed, :paid, application: a)
      end
      visit admin_user_path(user)

      expect(page).to have_css("h1", text: user.full_name)
      expect(page).to have_css("h2", text: "Applications", count: 1)
      applications.each do |application|
        within(".govuk-summary-card", text: application.course.name.to_s) do |summary_card|
          expect(summary_card).to have_summary_item("Course", application.course.name)
          expect(summary_card).to have_summary_item("Provider", application.lead_provider.name)
          expect(summary_card).to have_summary_item("Eligible for funding", "No")
          expect(summary_card).to have_summary_item("Provider approval status", "Pending")
          expect(summary_card).to have_summary_item("Funded place", "No")
          expect(summary_card).to have_summary_item("Training milestone reached", "Completed (paid)")
          expect(summary_card).to have_summary_item("Registration submission date", application.created_at.to_fs(:govuk_short))
        end
      end
    end

    scenario "changing a user's TRN" do
      visit admin_user_path(user)
      click_link "Change"

      expect(page).to have_css("h1", text: "Change TRN")
      within(first(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("Participant ID", user.ecf_id)
        expect(summary_list).to have_summary_item("TRN", user.trn)
      end

      # blank TRN
      click_on("Continue")
      expect(page).to have_content "can't be blank"

      fill_in("New TRN", with: "2345678")
      click_on("Continue")

      expect(page).to have_css("h1", text: user.full_name)

      within(".govuk-summary-card", text: "Overview") do |summary_card|
        expect(summary_card).to have_summary_item("TRN", "2345678", "Verified - manually")
      end

      expect(user.reload.trn).to eq "2345678"
    end
  end
end
