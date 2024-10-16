# frozen_string_literal: true

require "rails_helper"

RSpec.feature "ECF legacy spec for NPQ view contract", :ecf_api_disabled do
  include Helpers::AdminLogin
  include ActionView::Helpers::NumberHelper

  scenario "see the contract information for all courses of an NPQ lead provider" do
    given_i_am_logged_in_as_a_finance_user
    and_there_is_a_lead_provider_with_contracts
    when_i_visit_the_statement_page
    and_i_click_on_view_contract
    then_i_see_contract_information_for_each_course
  end

  def and_there_is_a_lead_provider_with_contracts
    @lead_provider = create(:lead_provider)

    @statement = create(
      :statement,
      lead_provider: @lead_provider,
    )

    @leading_teaching = create(:course, :leading_teaching)
    @leading_behaviour_culture = create(:course, :leading_behaviour_culture)
    @leading_primary_mathematics = create(:course, :leading_primary_mathmatics)
    @schedule = create(:schedule, :npq_leadership_autumn)
    @specialist_schedule = create(:schedule, :npq_specialist_autumn)

    @lt = create(:contract, course: @leading_teaching, statement: @statement)
    @lbc = create(:contract, course: @leading_behaviour_culture, statement: @statement)
    @lpm = create(:contract, course: @leading_primary_mathematics, statement: @statement)
  end

  def given_i_am_logged_in_as_a_finance_user
    sign_in_as(create(:admin))
  end

  def when_i_visit_the_statement_page
    visit "/npq-separation/admin/finance/statements/#{@statement.id}"
  end

  def and_i_click_on_view_contract
    find("span", text: "Contract Information").click
  end

  def then_i_see_contract_information_for_each_course
    within first(".govuk-details__text", visible: false) do
      expect(page).to have_content(@leading_teaching.name)
      expect(page).to have_content(@lt.recruitment_target)
      expect(page).to have_content(number_to_currency(@lt.per_participant))
      expect(page).to have_content(@leading_behaviour_culture.name)
      expect(page).to have_content(@lbc.recruitment_target)
      expect(page).to have_content(number_to_currency(@lbc.per_participant))
      expect(page).to have_content(@leading_primary_mathematics.name)
      expect(page).to have_content(@lpm.recruitment_target)
      expect(page).to have_content(number_to_currency(@lpm.per_participant))
    end
  end
end
