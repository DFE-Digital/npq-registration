require "rails_helper"

RSpec.feature "Listing and viewing statements", :ecf_api_disabled, type: :feature do
  include Helpers::AdminLogin

  let(:statements_per_page) { Pagy::DEFAULT[:limit] }

  before do
    create_list(:statement, statements_per_page + 1)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of statements" do
    visit(npq_separation_admin_finance_statements_path)

    expect(page).to have_css("h1", text: "Statements")

    Statement.order(payment_date: :asc).limit(statements_per_page).each do |statement|
      expect(page).to have_link("View", href: npq_separation_admin_finance_statement_path(statement))
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of statements" do
    visit(npq_separation_admin_finance_statements_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "viewing statement details" do
    visit(npq_separation_admin_finance_statements_path)

    statement = Statement.order(payment_date: :asc).first

    click_link("View", href: npq_separation_admin_finance_statement_path(statement))

    expect(page).to have_css("h1", text: "Statement #{statement.id}")

    within(".govuk-summary-list") do |summary_list|
      start_year = statement.cohort.start_year
      expect(summary_list).to have_summary_item("ID", statement.id)
      expect(summary_list).to have_summary_item("ECF ID", statement.ecf_id)
      expect(summary_list).to have_summary_item("Lead provider", statement.lead_provider.name)
      expect(summary_list).to have_summary_item("Cohort", "#{start_year}/#{start_year.next - 2000}")
      expect(summary_list).to have_summary_item("Status", statement.state.humanize)
    end
  end

  scenario "marking a statement as paid" do
    statement = create(:statement, :payable)
    create(:declaration, :payable, statement:)

    visit(npq_separation_admin_finance_statement_path(statement))
    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{Date::MONTHNAMES[statement.month]} #{statement.year} statement details")
    expect(page).to have_css(".statement-details-component", text: "Output payment")

    perform_enqueued_jobs do
      check "Yes, I'm ready to authorise this for payment", visible: :all
      click_button "Authorise for payment"
    end

    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    expect(page).to have_css(".govuk-tag", text: /Authorised for payment at 1?\d:\d\d[ap]m on \d?\d [A-Z][a-z]{2} 20\d\d/)
  end

  scenario "marking a statement as paid before job has run" do
    statement = create(:statement, :payable)
    create(:declaration, :payable, statement:)

    visit(npq_separation_admin_finance_statement_path(statement))
    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{Date::MONTHNAMES[statement.month]} #{statement.year} statement details")
    expect(page).to have_css(".statement-details-component", text: "Output payment")

    check "Yes, I'm ready to authorise this for payment", visible: :all
    click_button "Authorise for payment"

    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    expect(page).to have_css(".govuk-notification-banner__title", text: "Authorising for payment")
    expect(page).to have_css(".govuk-notification-banner__content", text: /Requested at \d\d?:\d\d[ap]m/)
  end

  describe "ECF legacy spec for show statement", :js do
    let(:cohort)              { create(:cohort, :current) }
    let(:course)              { create(:course, :leading_literacy) }
    let(:maths_course)        { create(:course, :leading_primary_mathmatics) }
    let(:lead_provider)       { create(:lead_provider) }
    let(:statement)           { create(:statement, :payable, lead_provider:) }
    let(:application)         { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:) }
    let(:another_application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:) }
    let(:contract_template)   { create(:contract_template, monthly_service_fee: nil) }

    before do
      create(:schedule, :npq_specialist_autumn, cohort:)
      create(:contract, course:, statement:, contract_template:)
    end

    describe "Statement authorise for payment", skip: "CPDNPQ-2142" do
      scenario "successfully authorising" do
        and_multiple_declarations_exist

        when_i_visit_the_npq_financial_statements_page

        then_i_see("National professional qualifications (NPQs)")

        and_i_see_authorise_for_payment_button
        and_i_see_save_as_pdf_link
        when_i_click_the_authorise_for_payment_button

        then_i_see("Check #{statement.name} statement details before authorising for payment")

        when_i_do_all_assurance_checks

        expect {
          when_i_click_the_authorise_for_payment_button
        }.to have_enqueued_job(
          Finance::Statements::MarkAsPaidJob,
        ).with(statement_id: statement.id).on_queue("default")

        then_i_see("Authorising for payment")
        then_i_see("Requested at #{statement.reload.marked_as_paid_at.strftime('%-I:%M%P on %-e %b %Y')}. This may take up to 15 minutes. Refresh to see the updated statement.")

        when_i_visit_the_npq_financial_statements_page

        then_i_do_not_see("Authorised for payment at #{statement.marked_as_paid_at.in_time_zone('London').strftime('%-I:%M%P on %-e %b %Y')}")
      end

      scenario "successfully authorised", :perform_jobs do
        and_multiple_declarations_exist

        when_i_visit_the_npq_financial_statements_page

        then_i_see("National professional qualifications (NPQs)")

        and_i_see_authorise_for_payment_button
        when_i_click_the_authorise_for_payment_button

        then_i_see("Check #{statement.name} statement details before authorising for payment")

        when_i_do_all_assurance_checks
        when_i_click_the_authorise_for_payment_button

        then_i_do_not_see("Authorising for payment")

        when_i_visit_the_npq_financial_statements_page

        then_i_see("Authorised for payment at #{Finance::Statement.find(statement.id).marked_as_paid_at.in_time_zone('London').strftime('%-I:%M%P on %-e %b %Y')}")
      end

      scenario "missing doing assurance checks" do
        and_multiple_declarations_exist

        when_i_visit_the_npq_financial_statements_page

        then_i_see("National professional qualifications (NPQs)")

        and_i_see_authorise_for_payment_button
        when_i_click_the_authorise_for_payment_button

        then_i_see("Check #{statement.name} statement details before authorising for payment")

        when_i_click_the_authorise_for_payment_button

        then_i_do_not_see("Authorising for payment")
        then_i_see("Confirm all necessary assurance checks have been done before authorising this statement for payment")
      end
    end

    describe "Statement with a special course" do
      scenario "Maths as special course" do
        and_multiple_declarations_exist
        and_multiple_declarations_exist_with_special_course

        when_i_visit_the_npq_financial_statements_page

        then_i_see("Statement #{statement.id}")
        and_i_see_special_course_warning
        and_i_see_special_course_payment_overview
      end

      scenario "No special course" do
        and_multiple_declarations_exist

        when_i_visit_the_npq_financial_statements_page

        then_i_do_not_see_special_course
      end
    end

    def when_i_visit_the_npq_financial_statements_page
      visit("/npq-separation/admin/finance/statements/#{statement.id}")
    end

    def then_i_see(string)
      expect(page).to have_content(string)
    end

    def and_i_see(string)
      expect(page).to have_content(string)
    end

    def then_i_do_not_see(string)
      expect(page).not_to have_content(string)
    end

    def and_multiple_declarations_exist
      travel_to statement.deadline_date do
        create(:declaration, :eligible, lead_provider:, application:, statement:)
        create(:declaration, :eligible, lead_provider:, application: another_application, statement:)
      end
    end

    def and_multiple_declarations_exist_with_special_course
      create(
        :contract,
        statement:,
        course: maths_course,
      ).tap { _1.contract_template.update! special_course: true }

      maths_application = create(:application, :accepted, :eligible_for_funding, course: maths_course, lead_provider:)

      travel_to statement.deadline_date do
        create(:declaration, :eligible, application: maths_application, lead_provider:, statement:)
      end
    end

    def and_i_see_authorise_for_payment_button
      expect(page).to have_button("Authorise for payment")
    end

    def and_i_see_save_as_pdf_link
      expected_filename = "#{npq_lead_provider.name} #{statement.name} NPQ Statement (#{cohort.start_year} Cohort)"
      expect(page).to have_css("a[data-filename='#{expected_filename}']", text: "Save as PDF")
    end

    def when_i_click_the_authorise_for_payment_button
      click_button "Authorise for payment", class: "govuk-button", type: "submit"
    end

    def when_i_do_all_assurance_checks
      check("Yes, I'm ready to authorise this for payment", allow_label_click: true)
    end

    def and_i_see_special_course_warning
      within ".govuk-warning-text" do
        have_content("#{maths_course.name} has standalone payments")
        have_link("View payments for this course", href: "#standalone_payments")
      end
    end

    def and_i_see_special_course_payment_overview
      within "h4#standalone_payments" do
        have_content("Standalone payments")
      end
      within "h4#standalone_payments + .app-statement-block h2" do
        have_content("Leading primary mathematics")
      end
    end

    def then_i_do_not_see_special_course
      expect(page).not_to have_button("Standalone payments")
      expect(page).not_to have_link("View payments for this course")
    end
  end
end
