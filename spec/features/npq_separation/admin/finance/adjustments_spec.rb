# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Adjustments", type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement) }
  let(:payable_statement) { create(:statement, :payable) }
  let(:paid_statement) { create(:statement, :paid) }

  before { sign_in_as(create(:admin)) }

  scenario "add adjustment" do
    visit(npq_separation_admin_finance_statement_path(statement))

    click_on "Make adjustment"

    expect(page).to have_css("h1", text: "Make adjustment")

    # check presence validation
    fill_in "Amount", with: ""
    click_on "Continue"

    expect(page).to have_text("You must enter a description for the adjustment")
    expect(page).to have_text("You must enter an adjustment amount")

    # check adjustment creation
    fill_in "adjustment[description]", with: "Adjustment description"
    fill_in "Amount", with: "100"
    click_on "Continue"

    expect(page).to have_css("h1", text: "You’ve made an adjustment")
    expect(page).to have_text("Adjustment description")
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
    expect(page).to have_text("Adjustment description")
    expect(page).to have_text("£100")
    expect(page).to have_text("Second adjustment")
    expect(page).to have_text("£200")
    expect(page).to have_text("Do you need to add another adjustment?")

    choose "No", visible: :all
    click_on "Continue"

    # check adjustments appear on statement page
    expect(page).to have_current_path(npq_separation_admin_finance_statement_path(statement))
    expect(page).to have_text("Adjustment description")
    expect(page).to have_text("£100")
    expect(page).to have_text("Second adjustment")
    expect(page).to have_text("£200")
    within(:xpath, "//h2[text()='Additional adjustments']/following-sibling::table") do |table|
      expect(table).to have_text("Total")
      expect(table).to have_text("£300")
    end

    # add further adjustment
    click_on "Make adjustment"

    expect(page).not_to have_text("Adjustment description")
    expect(page).not_to have_text("£100")
    expect(page).not_to have_text("Second adjustment")
    expect(page).not_to have_text("£200")
  end

  scenario "statement is marked as payable" do
    visit(npq_separation_admin_finance_statement_path(payable_statement))

    expect(page).not_to have_link "Make adjustment"
  end

  scenario "statement is marked as paid" do
    visit(npq_separation_admin_finance_statement_path(paid_statement))

    expect(page).not_to have_link "Make adjustment"
  end
end
