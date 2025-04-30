# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Adjustments", type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement) }
  let(:payable_statement) { create(:statement, :payable) }
  let(:paid_statement) { create(:statement, :paid) }

  context "when not logged in" do
    scenario "statement page is inaccessible" do
      visit(npq_separation_admin_finance_statement_path(statement))
      expect(page).to have_current_path(sign_in_path)
    end

    scenario "adjustments page is inaccessible" do
      visit(new_npq_separation_admin_finance_statement_adjustment_path(statement))
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as(create(:admin)) }

    scenario "add adjustment" do
      visit(npq_separation_admin_finance_statement_path(statement))
      expect(page).to have_text("There are no adjustments")

      click_on "Make adjustment"
      expect(page).to have_css("h1", text: "Make adjustment")

      # check cancel link
      click_on "Cancel"
      expect(page).to have_current_path(npq_separation_admin_finance_statement_path(statement))

      # check presence validation
      click_on "Make adjustment"
      fill_in "Amount", with: ""
      click_on "Continue"
      expect(page).to have_text("You must enter a description for the adjustment")
      expect(page).to have_text("You must enter an adjustment amount")

      # check adjustment creation
      fill_in "adjustment[description]", with: "First adjustment"
      fill_in "Amount", with: "100"
      click_on "Continue"
      expect(page).to have_css("h1", text: "You’ve made an adjustment")
      expect(page).to have_text("First adjustment")
      expect(page).to have_text("£100")
      expect(page).to have_text("Do you need to add another adjustment?")

      # check "add another" radio button validation
      click_on "Continue"
      expect(page).to have_text("Select if you need to add another adjustment")
      choose "Yes", visible: :all
      click_on "Continue"
      expect(page).to have_css("h1", text: "Make adjustment")

      # check creating a second adjustment
      fill_in "adjustment[description]", with: "Second adjustment"
      fill_in "Amount", with: "200"
      click_on "Continue"
      expect(page).to have_css("h1", text: "You’ve made an adjustment")
      expect(page).to have_text("First adjustment")
      expect(page).to have_text("£100")
      expect(page).to have_text("Second adjustment")
      expect(page).to have_text("£200")
      expect(page).to have_text("Do you need to add another adjustment?")

      choose "No", visible: :all
      click_on "Continue"

      # check adjustments appear on statement page
      expect(page).to have_current_path(npq_separation_admin_finance_statement_path(statement))
      expect(page).to have_text("First adjustment")
      expect(page).to have_text("£100")
      expect(page).to have_text("Second adjustment")
      expect(page).to have_text("£200")
      within(:xpath, "//h2[text()='Additional adjustments']/following-sibling::table") do |table|
        expect(table).to have_text("Total")
        expect(table).to have_text("£300")
      end

      # add further adjustment
      click_on "Make adjustment"
      fill_in "adjustment[description]", with: "Third adjustment"
      fill_in "Amount", with: "400"
      click_on "Continue"
      expect(page).not_to have_text("First adjustment")
      expect(page).not_to have_text("£100")
      expect(page).not_to have_text("Second adjustment")
      expect(page).not_to have_text("£200")
      expect(page).to have_text("Third adjustment")
      expect(page).to have_text("£400")

      # check editing adjustment from adjustments list page
      click_on "Edit"
      # check cancel link
      click_on "Cancel"
      expect(page).to have_current_path(npq_separation_admin_finance_statement_adjustments_path(statement, show_all_adjustments: false))
      # edit for real
      click_on "Edit"
      fill_in "adjustment[description]", with: "Third adjustment edited"
      fill_in "Amount", with: "300"
      click_on "Continue"
      expect(page).not_to have_text("First adjustment")
      expect(page).not_to have_text("£100")
      expect(page).not_to have_text("Second adjustment")
      expect(page).not_to have_text("£200")
      expect(page).to have_text("Third adjustment edited")
      expect(page).to have_text("£300")

      # check deleting adjustment
      click_on "Remove"
      expect(page).to have_css("h1", text: "Are you sure you want to remove this adjustment?")
      # check cancel link
      click_on "Cancel"
      expect(page).not_to have_text("First adjustment")
      expect(page).not_to have_text("£100")
      expect(page).not_to have_text("Second adjustment")
      expect(page).not_to have_text("£200")
      expect(page).to have_text("Third adjustment edited")
      expect(page).to have_text("£300")
      expect(page).to have_current_path(npq_separation_admin_finance_statement_adjustments_path(statement, show_all_adjustments: false))
      # delete for real
      click_on "Remove"
      expect(page).to have_css("h1", text: "Are you sure you want to remove this adjustment?")
      click_on "Remove"
      expect(page).to have_text("There are no adjustments")

      choose "No", visible: :all
      click_on "Continue"
      expect(page).to have_text("First adjustment")
      expect(page).to have_text("£100")
      expect(page).to have_text("Second adjustment")
      expect(page).to have_text("£200")
      expect(page).not_to have_text("Third adjustment edited")

      # edit adjustment from statement page
      click_on "Change or remove"
      expect(page).not_to have_text("You’ve made an adjustment")
      expect(page).to have_text("First adjustment")
      expect(page).to have_text("£100")
      expect(page).to have_text("Second adjustment")
      expect(page).to have_text("£200")

      within ".govuk-table__row:nth-of-type(2)" do
        click_on "Edit"
      end
      # check cancel link
      click_on "Cancel"
      expect(page).to have_current_path(npq_separation_admin_finance_statement_adjustments_path(statement, show_all_adjustments: true))
      # edit for real
      within ".govuk-table__row:nth-of-type(2)" do
        click_on "Edit"
      end
      fill_in "adjustment[description]", with: "Second adjustment edited"
      fill_in "Amount", with: "500"
      click_on "Continue"
      expect(page).to have_text("Second adjustment edited")
      expect(page).to have_text("£500")
      expect(page).to have_text("Do you need to add another adjustment?")

      choose "No", visible: :all
      click_on "Continue"
      expect(page).to have_text("Second adjustment edited")
      expect(page).to have_text("£500")

      # delete adjustment from statement page
      click_on "Change or remove"
      within ".govuk-table__row:nth-of-type(2)" do
        click_on "Remove"
      end
      # check cancel link
      click_on "Cancel"
      expect(page).to have_current_path(npq_separation_admin_finance_statement_adjustments_path(statement, show_all_adjustments: true))
      expect(page).to have_text("Second adjustment edited")
      expect(page).to have_text("£500")
      # delete for real
      within ".govuk-table__row:nth-of-type(2)" do
        click_on "Remove"
      end
      click_on "Remove"
      expect(page).to have_text("First adjustment")
      expect(page).to have_text("£100")
      expect(page).not_to have_text("Second adjustment edited")
      expect(page).not_to have_text("£500")

      choose "No", visible: :all
      click_on "Continue"

      expect(page).not_to have_text("Second adjustment edited")
      expect(page).not_to have_text("£500")

      # check adding another adjustment when going via the 'Change or remove' link
      click_on "Change or remove"
      choose "Yes", visible: :all
      click_on "Continue"
      # check cancel link
      click_on "Cancel"
      expect(page).to have_current_path(npq_separation_admin_finance_statement_adjustments_path(statement, show_all_adjustments: true))
      # add another for real
      choose "Yes", visible: :all
      click_on "Continue"
      fill_in "adjustment[description]", with: "Fourth adjustment"
      fill_in "Amount", with: "600"
      click_on "Continue"
      expect(page).to have_text("First adjustment")
      expect(page).to have_text("£100")
      expect(page).to have_text("Fourth adjustment")
      expect(page).to have_text("£600")
    end

    scenario "statement is marked as payable" do
      visit(npq_separation_admin_finance_statement_path(payable_statement))

      expect(page).not_to have_link "Make adjustment"
    end

    scenario "statement is marked as paid" do
      visit(npq_separation_admin_finance_statement_path(paid_statement))

      expect(page).not_to have_link "Make adjustment"
    end

    scenario "statement moved to payable whilst creating adjustment" do
      visit(new_npq_separation_admin_finance_statement_adjustment_path(statement))

      statement.update!(state: :payable)

      fill_in "adjustment[description]", with: "new adjustment"
      click_on "Continue"

      expect(page).to have_text("The statement has to be open for adjustments to be made")
      expect(Adjustment.count).to be_zero
    end

    scenario "statement moved to payable whilst editing adjustment" do
      adjustment = create(:adjustment, statement:, description: "adjustment description", amount: 100)

      visit(edit_npq_separation_admin_finance_statement_adjustment_path(statement, adjustment))

      statement.update!(state: :payable)

      fill_in "adjustment[description]", with: "adjustment edited"
      click_on "Continue"

      expect(page).to have_text("The statement has to be open for adjustments to be made")
      expect(Adjustment.last.description).to eq("adjustment description")
    end

    scenario "statement moved to payable whilst deleting adjustment" do
      adjustment = create(:adjustment, statement:, description: "adjustment description", amount: 100)

      visit(delete_npq_separation_admin_finance_statement_adjustment_path(statement, adjustment))

      statement.update!(state: :payable)

      click_on "Remove"

      expect(page).to have_text("The statement has to be open for adjustments to be made")
      expect(Adjustment.count).to eq 1
    end
  end
end
