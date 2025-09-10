require "rails_helper"

RSpec.feature "Creating statements", type: :feature do
  include Helpers::AdminLogin
  include Helpers::FileHelper
  include Helpers::StatementsHelper

  let(:cohort) { create(:cohort) }

  before do
    sign_in_as admin
    visit npq_separation_admin_cohort_path(cohort)
  end

  context "when logged in as a regular admin" do
    let(:admin) { create(:admin) }

    scenario "is not possible" do
      expect(page).not_to have_selector(:link_or_button, "Create statements")

      visit(new_npq_separation_admin_cohort_statement_path(cohort))
      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_text("Unauthorized")
    end
  end

  context "when logged in as a super admin" do
    let(:admin) { create(:super_admin) }

    scenario "is possible" do
      click_on "Create statements"

      attach_file "statements_bulk_creator[statements_csv_file]", statements_csv.path, make_visible: true
      attach_file "statements_bulk_creator[contracts_csv_file]", contracts_csv.path, make_visible: true

      expect {
        click_on "Continue to preview"
        expect(page).to have_css("h1", text: /Confirm new cohort .+ statements/)
      }.to not_change(Statement, :count)
        .and not_change(Contract, :count)
        .and not_change(ContractTemplate, :count)

      find("summary", text: "Statement dates").click
      expect(page).to have_table rows: [
        ["February 2025", "25 Dec 2024", "26 Jan 2025", "Yes"],
        ["March 2025", "26 Jan 2025", "27 Feb 2025", "No"],
        ["April 2025", "24 Feb 2025", "25 Mar 2025", "No"],
      ]

      find("summary", text: "2 contracts for #{LeadProvider.first.name} statements").click
      expect(page).to have_table rows: [
        [Course.first.name, "30", "£1,000", "12", "No", "£100"],
        [Course.last.name, "50", "£400", "6", "Yes", "£200"],
      ]

      find("summary", text: "1 contract for #{LeadProvider.last.name} statements").click
      expect(page).to have_table rows: [
        [Course.first.name, "20", "£750", "9", "No", "£0"],
      ]

      expect {
        click_on "Create statements"
        expect(page).to have_text("6 statements created successfully")
      }.to change(Statement, :count).by(6)
          .and change(Contract, :count).by(9)
          .and change(ContractTemplate, :count).by(3)
    end

    scenario "downloading examples" do
      click_on "Create statements"

      find("summary", text: "Example statements CSV").click
      click_on "Download empty statements template"

      csv_file = "#{Capybara.save_path}/statements.csv"
      wait_for_file_to_be_created(csv_file)
      csv = CSV.read(csv_file)
      expect(csv.count).to eq(1)

      find("summary", text: "Example contracts CSV").click
      click_on "Download empty contracts template"

      csv_file = "#{Capybara.save_path}/contracts.csv"
      wait_for_file_to_be_created(csv_file)
      csv = CSV.read(csv_file)
      expect(csv.count).to eq(1)

      visit npq_separation_admin_cohort_path(cohort)
      click_on "Download contracts CSV"
      csv_file = "#{Capybara.save_path}/contracts.csv"
      wait_for_file_to_be_created(csv_file)
    end
  end
end
