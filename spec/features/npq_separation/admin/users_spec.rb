require "rails_helper"

RSpec.feature "User administration", type: :feature do
  include Helpers::AdminLogin

  let(:users_per_page) { Pagy::DEFAULT[:limit] }
  let(:user) { User.first }

  before do
    create_list(:user, users_per_page, :with_get_an_identity_id)
    user.update!(national_insurance_number: "QQ123456C")
    sign_in_as(create(:admin))
  end

  feature "listing users" do
    scenario "viewing the list of users" do
      visit(npq_separation_admin_users_path)

      expect(page).to have_css("h1", text: "Users")

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

      fill_in("Find a user", with: user.email)
      click_on("Search")

      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to have_css("tbody tr", text: user.full_name)
    end
  end

  feature "viewing a user" do
    scenario "shows side navigation with current user" do
      visit(npq_separation_admin_user_path(user))

      within "#side-navigation" do |side_navigation|
        expect(side_navigation).to have_content("Overview")
        expect(side_navigation).to have_content(user.full_name)
        expect(side_navigation).to have_link("All applications", href: "/npq-separation/admin/applications")
        expect(side_navigation).to have_link("In review", href: "/npq-separation/admin/applications/reviews")
      end
    end

    scenario "shows user details" do
      visit npq_separation_admin_user_path(user)

      expect(page).to have_css("h1", text: user.full_name)

      expect(page).to have_content("User ID: #{user.ecf_id}")
      expect(page).to have_content("Email: #{user.email}")
      expect(page).to have_content("Date of birth: #{user.date_of_birth.to_fs(:govuk_short)}")
      expect(page).to have_content("National Insurance: #{user.national_insurance_number}")
      expect(page).to have_content("TRN: #{user.trn} Not verified")
      expect(page).to have_content("Get an Identity ID: #{user.uid}")
    end

    scenario "renders when attributes with method chains are nil" do
      user.update!(date_of_birth: nil)
      visit npq_separation_admin_user_path(user)

      expect(page).to have_content("Date of birth:")
    end

    scenario "shows a message if the user has no applications" do
      visit npq_separation_admin_user_path(user)

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
      visit npq_separation_admin_user_path(user)

      expect(page).to have_css("h1", text: user.full_name)
      applications.each do |application|
        within(".govuk-summary-card", text: "#{application.course.name} registration") do |summary_card|
          expect(summary_card).to have_summary_item("NPQ course", application.course.name)
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
      visit npq_separation_admin_user_path(user)
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
      expect(page).to have_content("TRN: 2345678 Verified - manually")
      expect(user.reload.trn).to eq "2345678"
    end
  end
end
