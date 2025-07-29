# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement - change payment per participant", type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement, month: Time.zone.today.month, year: Time.zone.today.year) }
  let!(:contract) { create(:contract, course: create(:course, :leading_teaching), statement:) }
  let(:future_statement) { create(:statement, month: Time.zone.today.month + 1, year: Time.zone.today.year, lead_provider: statement.lead_provider) }
  let!(:future_contract) { create(:contract, course: contract.course, statement: future_statement) }

  before do
    sign_in_as(create(:admin, super_admin: true))
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

    expect(page).to have_current_path(npq_separation_admin_finance_change_per_participant_path(contract))

    # check error message

    fill_in "contracts-change-per-participant-per-participant-field", with: ""
    click_button "Continue"
    expect(page).to have_content("Enter the new amount")

    # check updating the value

    fill_in "contracts-change-per-participant-per-participant-field-error", with: "123"
    click_button "Continue"
    click_button "Confirm and submit"

    expect(page).to have_content("#{contract.course.name} payment per participant changed" \
                                 " for all #{statement.lead_provider.name} contracts"\
                                 " in the #{statement.cohort.start_year} cohort" \
                                 " from #{Time.zone.today.strftime('%B %Y')} onwards")
    expect(contract.reload.per_participant).to eq(123)
    expect(future_contract.reload.per_participant).to eq(123)
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
    expect(page).to have_current_path(npq_separation_admin_finance_change_per_participant_path(contract))

    # check cancel
    fill_in "contracts-change-per-participant-per-participant-field", with: "123"
    click_button "Continue"

    click_link "Cancel"
    expect(page).to have_current_path(npq_separation_admin_finance_statement_path(statement))
  end
end
