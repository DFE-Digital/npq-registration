# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement - change payment per participant", type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement) }
  let(:contract) { Contract.joins(:course).order(identifier: :asc).first }

  before do
    create(:contract, course: create(:course, :leading_teaching), statement:)
    create(:contract, course: create(:course, :leading_behaviour_culture), statement:)
    create(:contract, course: create(:course, :leading_primary_mathmatics), statement:)
    sign_in_as(create(:admin))
  end

  scenario "updating per participant amount" do
    visit(npq_separation_admin_finance_statement_path(statement))
    find("span", text: "Contract Information").click
    within("#contract-information tbody tr:nth-of-type(1)") do
      click_link "Change"
    end

    fill_in "contracts-change-per-participant-per-participant-field", with: "123"
    click_button "Continue"

    expect(page).to have_content("£#{Contract.first.per_participant}")
    expect(page).to have_content("123")

    # check change link
    click_link "Change"

    expect(page).to have_current_path(npq_separation_admin_finance_statement_change_per_participant_path(statement, contract))

    # check error message

    fill_in "contracts-change-per-participant-per-participant-field", with: ""
    click_button "Continue"
    expect(page).to have_content("Enter the new amount")

    # check updating the value

    fill_in "contracts-change-per-participant-per-participant-field-error", with: "123"
    click_button "Continue"
    click_button "Confirm and submit"

    expect(page).to have_content("#{contract.course.name} payment per participant changed")
    expect(contract.reload.per_participant).to eq(123)
  end

  scenario "back and cancel links" do
    visit(npq_separation_admin_finance_statement_path(statement))
    find("span", text: "Contract Information").click
    within("#contract-information tbody tr:nth-of-type(1)") do
      click_link "Change"
    end

    # check back
    click_link "Back"
    expect(page).to have_current_path(npq_separation_admin_finance_statement_path(statement))

    # check cancel
    find("span", text: "Contract Information").click
    within("#contract-information tbody tr:nth-of-type(1)") do
      click_link "Change"
    end

    click_link "Cancel"
    expect(page).to have_current_path(npq_separation_admin_finance_statement_path(statement))

    # check confirmation page

    find("span", text: "Contract Information").click
    within("#contract-information tbody tr:nth-of-type(1)") do
      click_link "Change"
    end
    fill_in "contracts-change-per-participant-per-participant-field", with: "123"
    click_button "Continue"

    # check back
    click_link "Back"
    expect(page).to have_current_path(npq_separation_admin_finance_statement_change_per_participant_path(statement, contract))

    # check cancel
    fill_in "contracts-change-per-participant-per-participant-field", with: "123"
    click_button "Continue"

    click_link "Cancel"
    expect(page).to have_current_path(npq_separation_admin_finance_statement_path(statement))
  end

  scenario "edge-case - updating the hidden field value on the confirmation screen" do
    visit(npq_separation_admin_finance_statement_path(statement))
    find("span", text: "Contract Information").click
    within("#contract-information tbody tr:nth-of-type(1)") do
      click_link "Change"
    end

    fill_in "contracts-change-per-participant-per-participant-field", with: "123"
    click_button "Continue"
    page.find("input#contracts_change_per_participant_per_participant", visible: false).set("")
    click_button "Confirm and submit"

    expect(page).to have_content("Enter the new amount")
  end
end
