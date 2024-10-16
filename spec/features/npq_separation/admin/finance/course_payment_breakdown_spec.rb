# frozen_string_literal: true

require "rails_helper"

RSpec.feature "ECF legacy spec for course payment breakdown", :ecf_api_disabled, :js, type: :feature do
  include ActionView::Helpers::NumberHelper
  include Helpers::AdminLogin

  # This needs to be hardcoded to test targetted funding functionality
  let(:cohort) { Cohort.find_by(start_year: 2021) || create(:cohort, start_year: 2021) }

  let(:leadership_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }
  let(:specialist_schedule) { create(:schedule, :npq_specialist_autumn, cohort:) }

  let(:lead_provider) { create(:lead_provider) }

  let(:course_leading_teaching)             { create(:course, :leading_teaching) }
  let(:course_leading_behaviour_culture)    { create(:course, :leading_behaviour_culture) }
  let(:course_leading_teaching_development) { create(:course, :leading_teaching_development) }

  let!(:statement) do
    create(
      :statement,
      lead_provider:,
      cohort:,
    )
  end

  let!(:leading_teaching_contract) { create(:contract, statement:, course: course_leading_teaching) }
  let!(:leading_behaviour_culture_contract) { create(:contract, statement:, course: course_leading_behaviour_culture).tap { _1.contract_template.update! per_participant: 810 } }
  let!(:leading_teaching_development_contract) { create(:contract, statement:, course: course_leading_teaching_development) }

  let(:cohort_current) { Cohort.current }

  before do
    leadership_schedule
    specialist_schedule
  end

  scenario "See a payment breakdown per NPQ course and a payment breakdown of each individual NPQ courses for each provider" do
    given_i_am_logged_in_as_a_finance_user
    and_those_courses_have_submitted_declarations
    when_i_visit_the_payment_breakdown_page

    then_i_should_see_correct_statement_summary
    then_i_should_see_correct_course_summary
    then_i_should_see_correct_output_payment_breakdown
    then_i_should_not_see_service_fee
    then_i_should_see_the_correct_total
    and_the_page_should_be_accessible

    expect(page)
      .to have_link("Download declarations (CSV)", href: npq_separation_admin_finance_assurance_report_path(statement, format: :csv))

    when_i_click_on_view_within_statement_summary
    then_i_see_voided_declarations
    click_on "Back"
    when_i_click_on_view_contract
    then_i_see_contract_information
    and_the_page_should_be_accessible
  end

  scenario "NPQ Contracts with calculated service fees" do
    given_i_am_logged_in_as_a_finance_user
    and_those_courses_have_submitted_declarations
    and_contracts_have_service_fee_set_nil
    when_i_visit_the_payment_breakdown_page

    then_i_should_see_correct_statement_summary
    then_i_should_see_correct_total_service_fees
    then_i_should_see_correct_course_summary
    then_i_should_see_correct_output_payment_breakdown
    then_i_should_see_correct_service_fee_payment_breakdown
    then_i_should_see_the_correct_total_with_service_fees
    and_the_page_should_be_accessible

    expect(page)
      .to have_link("Download declarations (CSV)", href: npq_separation_admin_finance_assurance_report_path(statement, format: :csv))

    when_i_click_on_view_within_statement_summary
    then_i_see_voided_declarations
    click_on "Back"
    when_i_click_on_view_contract
    then_i_see_contract_information
    and_the_page_should_be_accessible
  end

  context "with targeted delivery funding" do
    let(:cohort) { create(:cohort, :current) }

    scenario "See payment breakdown with targeted delivery funding" do
      given_i_am_logged_in_as_a_finance_user
      and_those_courses_have_submitted_declarations
      and_contracts_have_service_fee_set_nil
      and_there_are_targeted_delivery_funding_declarations
      when_i_visit_the_payment_breakdown_page

      then_i_should_see_correct_statement_summary
      then_i_should_see_correct_course_summary
      then_i_should_see_correct_output_payment_breakdown
      then_i_should_see_correct_service_fee_payment_breakdown_below_targeted_delivery_funding
      then_i_should_see_correct_targeted_delivery_funding_breakdown
      then_i_should_see_the_correct_total_including_targeted_delivery_funding
      and_the_page_should_be_accessible
    end
  end

  def given_i_am_logged_in_as_a_finance_user
    sign_in_as(create(:admin))
  end

  def and_contracts_have_service_fee_set_nil
    leading_teaching_contract.contract_template.update!(monthly_service_fee: nil)
    leading_behaviour_culture_contract.contract_template.update!(monthly_service_fee: nil)
    leading_teaching_development_contract.contract_template.update!(monthly_service_fee: nil)
  end

  def and_a_duplicate_contract_exists
    contract1 = statement.contracts.first
    statement.contracts.create!(
      course: contract1.course,
      contract_template: contract1.contract_template,
    )
  end

  def then_we_should_not_see_duplicate_courses
    course_titles = page.all("section.app-statement-block h2").map(&:text)
    expect(course_titles.count).to eql(course_titles.uniq.count)
  end

  def create_accepted_application(user, course, lead_provider)
    create(:application, :accepted, cohort:, course:, lead_provider:, user:)
  end

  def create_started_declarations(application, state = "submitted")
    travel_to(statement.deadline_date) do
      create(:declaration, application:, lead_provider:, state:)
    end
  end

  def and_those_courses_have_submitted_declarations
    [course_leading_teaching, course_leading_behaviour_culture, course_leading_teaching_development].each do |course|
      create_list(:user, 2)
        .map { |user| create_accepted_application(user, course, lead_provider) }

      create_list(:user, 3)
        .map { |user| create_accepted_application(user, course, lead_provider) }
        .map { |application| create_started_declarations(application) }

      create_list(:user, 4)
        .map { |user| create_accepted_application(user, course, lead_provider) }
        .map { |application| create_started_declarations(application, "eligible") }

      create_list(:user, 1)
        .map { |user| create_accepted_application(user, course, lead_provider) }
        .map { |application| create_started_declarations(application, "voided") }

      create_list(:user, 2)
        .map { |user| create_accepted_application(user, course, lead_provider) }
        .map { |application| create_started_declarations(application, "ineligible") }

      create_list(:user, 5)
        .map { |user| create_accepted_application(user, course, lead_provider) }
        .map { |application| create_started_declarations(application, "payable") }
    end

    Declaration
      .where(state: %w[ineligible voided eligible payable])
      .find_each do |declaration|
        create(:statement_item,
               statement:,
               declaration:,
               state: declaration.state)
      end
  end

  def and_there_are_targeted_delivery_funding_declarations
    user = create(:user)
    application = create_accepted_application(user, course_leading_behaviour_culture, lead_provider)
    application.eligible_for_funding = true
    application.targeted_delivery_funding_eligibility = true
    application.save!
    declaration = create_started_declarations(application)
    create(:statement_item, declaration:, statement:)
    travel_to(statement.deadline_date) do
      declaration.update! state: "payable"
    end
    @targeted_delivery_funding_declarations_count = 1
  end

  def then_i_should_see_correct_statement_summary
    then_i_should_see_correct_overall_payments
    then_i_should_see_correct_cut_off_date
    then_i_should_see_correct_overall_declarations
  end

  def then_i_should_see_correct_overall_payments
    within first(".app-statement-block") do
      expect(page).to have_content("Output payment\n#{number_to_currency total_output_payment}")
    end
  end

  def then_i_should_see_correct_total_service_fees
    within first(".app-statement-block") do
      expect(page).to have_content("Service fee\n#{number_to_currency total_service_fees_monthly}")
    end
  end

  def then_i_should_see_correct_cut_off_date
    within first(".app-statement-block") do
      expect(page).to have_content(statement.deadline_date.to_fs(:govuk))
    end
  end

  def then_i_should_see_correct_overall_declarations
    within first(".app-statement-block") do
      expect(page).to have_content("Total starts")
      expect(page).to have_content(total_starts)
      expect(page).to have_content("Total retained")
      expect(page).to have_content(total_retained)
      expect(page).to have_content("Total completed")
      expect(page).to have_content(total_completed)
      expect(page).to have_content("Total voids")
      expect(page).to have_content(total_voided)
    end
  end

  def then_i_should_see_correct_output_payment_breakdown
    within all(".app-statement-block")[1] do
      expect(page).to have_css("tr:nth-child(1) td:nth-child(1)", text: "Output payment")
      expect(page).to have_css("tr:nth-child(1) td:nth-child(2)", text: total_declarations(leading_behaviour_culture_contract))
      expect(page).to have_css("tr:nth-child(1) td:nth-child(3)", text: number_to_currency(162))
      expect(page).to have_css("tr:nth-child(1) td:nth-child(4)", text: number_to_currency(total_declarations(leading_behaviour_culture_contract) * 162.0))
    end
  end

  def when_i_visit_the_payment_breakdown_page
    visit "/npq-separation/admin/finance/statements/#{statement.id}"
  end

  def then_i_should_see_correct_course_summary
    within all(".app-statement-block")[1] do
      expect(page).to have_content("Started")
      expect(page).to have_content(total_participants_for(specialist_schedule.allowed_declaration_types.first))
      expect(page).to have_content("Total declarations")
      expect(page).to have_content(total_declarations(leading_behaviour_culture_contract))
    end
  end

  def when_i_click_on_view_within_statement_summary
    within first(".app-statement-block") do
      when_i_click_on("View")
    end
  end

  def then_i_see_voided_declarations
    first("table") do
      expect(page).to have_css("tr", count: 4) # headers + (3 * 1) # 1 for each of the 3 courses
    end
  end

  def then_i_should_see_correct_service_fee_payment_breakdown
    within all(".app-statement-block")[1] do
      expect(page).to have_css("tr:nth-child(2) td:nth-child(1)", text: "Service fee")
      expect(page).to have_css("tr:nth-child(2) td:nth-child(2)", text: leading_behaviour_culture_contract.recruitment_target)
      expect(page).to have_css("tr:nth-child(2) td:nth-child(3)", text: number_to_currency(17.05))
      expect(page).to have_css("tr:nth-child(2) td:nth-child(4)", text: number_to_currency(1_227.79))
    end
  end

  def then_i_should_not_see_service_fee
    expect(page).not_to have_content("Service fee")
  end

  def then_i_should_see_correct_service_fee_payment_breakdown_below_targeted_delivery_funding
    within all(".app-statement-block")[1] do
      expect(page).to have_css("tr:nth-child(3) td:nth-child(1)", text: "Service fee")
      expect(page).to have_css("tr:nth-child(3) td:nth-child(2)", text: leading_behaviour_culture_contract.recruitment_target)
      expect(page).to have_css("tr:nth-child(3) td:nth-child(3)", text: number_to_currency(17.05))
      expect(page).to have_css("tr:nth-child(3) td:nth-child(4)", text: number_to_currency(1_227.79))
    end
  end

  def then_i_should_see_correct_targeted_delivery_funding_breakdown
    within all(".app-statement-block")[1] do
      expect(page).to have_css("tr:nth-child(2) td:nth-child(1)", text: "Targeted delivery funding")
      expect(page).to have_css("tr:nth-child(2) td:nth-child(2)", text: 1)
      expect(page).to have_css("tr:nth-child(2) td:nth-child(3)", text: number_to_currency(100.0))
      expect(page).to have_css("tr:nth-child(2) td:nth-child(4)", text: number_to_currency(100.0))
    end
  end

  def then_i_should_see_the_correct_total
    within all(".app-statement-block")[1] do
      expect(page).to have_content("Course total")
      expect(page).to have_content(number_to_currency(1_458))
    end
  end

  def then_i_should_see_the_correct_total_with_service_fees
    within all(".app-statement-block")[1] do
      expect(page).to have_content("Course total")
      expect(page).to have_content(number_to_currency(1_458 + 1_227.79))
    end
  end

  def then_i_should_see_the_correct_total_including_targeted_delivery_funding
    within all(".app-statement-block")[1] do
      expect(page).to have_content("Course total")
      expect(page).to have_content(number_to_currency(1_620 + 100 + 1_227.79))
    end
  end

  def when_i_click_on(string)
    click_link_or_button string
  end

  def when_i_click_on_view_contract
    find("span", text: "Contract Information").click
  end

  def then_i_see_contract_information
    within first(".govuk-details__text") do
      expect(page).to have_content(course_leading_teaching.name)
      expect(page).to have_content(leading_teaching_contract.recruitment_target)
    end
  end

  def participants_per_declaration_type
    statement
      .declarations
      .billable
      .joins(:application)
      .where(applications: { course_id: leading_behaviour_culture_contract.course_id })
      .group(:declaration_type)
      .count
  end

  def total_participants_for(declaration_type)
    participants_per_declaration_type.fetch(declaration_type, 0)
  end

  def contracts
    statement.contracts
  end

  def output_payment_per_contract
    contracts.map { |contract| Statements::OutputPaymentCalculator.call(contract:, total_participants: statement_declarations_per_contract(contract)) }
  end

  def service_fees_per_contract
    contracts.map { |contract| Statements::ServiceFeesCalculator.call(contract:) }.compact
  end

  def total_service_fees_monthly
    service_fees_per_contract.sum { |service_fee| service_fee[:monthly] }
  end

  def total_output_payment
    output_payment_per_contract.sum { |output_payment| output_payment[:subtotal] }
  end

  def total_targeted_delivery_funding
    @targeted_delivery_funding_declarations_count.to_i * contracts.first.targeted_delivery_funding_per_participant
  end

  def total_payment
    total_service_fees_monthly + total_output_payment + total_targeted_delivery_funding
  end

  def overall_vat
    total_payment * (lead_provider.vat_chargeable ? 0.2 : 0.0)
  end

  def overall_total
    total_payment + overall_vat
  end

  def statement_declarations_per_contract(contract)
    statement
      .declarations
      .joins(:application)
      .where(state: %w[eligible payable paid], application: { course_id: contract.course.id })
      .merge(Declaration.distinct("(user_id, declaration_type)"))
      .count
  end

  def total_starts
    statement
      .statement_items
      .billable
      .joins(:declaration)
      .where(declarations: { declaration_type: "started" })
      .count
  end

  def statement_declarations
    statement.declarations.billable
  end

  def total_retained
    statement
      .statement_items
      .billable
      .joins(:declaration)
      .where(declarations: { declaration_type: %w[retained-1 retained-2] })
      .count
  end

  def total_completed
    statement
      .statement_items
      .billable
      .joins(:declaration)
      .where(declarations: { declaration_type: "completed" })
      .count
  end

  def total_voided
    voided_declarations.count
  end

  def voided_declarations
    statement.declarations.where(state: "voided").distinct("(user_id, declaration_type)")
  end

  def total_declarations(contract)
    statement
      .statement_items
      .billable
      .joins(declaration: :application)
      .where(applications: { course_id: contract.course_id })
      .count
  end
end
