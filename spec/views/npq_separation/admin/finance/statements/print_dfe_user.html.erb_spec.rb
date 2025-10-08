require "rails_helper"

RSpec.describe "npq_separation/admin/finance/statements/print_dfe_user", type: :view do
  subject { render }

  let(:rendered) { Capybara.string(subject) }
  let(:contract) { create(:contract, course: create(:course, :leading_teaching), statement:) }
  let(:special_contract) { create(:contract, contract_template: create(:contract_template, special_course: true), statement:) }
  let(:statement) { build(:statement, :paid, month: Time.zone.today.month, year: Time.zone.today.year) }
  let(:admin_user) { create(:admin) }

  before do
    contract
    assign(:statement, statement)
    assign(:special_contracts, [special_contract])
    assign(:contracts, [contract])
    without_partial_double_verification { allow(view).to receive(:current_admin).and_return(admin_user) }
  end

  it "shows the statement overview" do
    summary_card = rendered.find(".govuk-summary-card", text: "Overview")
    expect(summary_card).to have_summary_item("Cohort", statement.cohort.start_year)
    expect(summary_card).to have_summary_item("Output payment date", statement.payment_date.to_fs(:govuk))
    expect(summary_card).to have_summary_item("Status", statement.state.humanize)
    expect(summary_card).to have_summary_item("Statement ID", statement.ecf_id)
    expect(summary_card).to have_summary_item("Payment run", "Yes")
    expect(summary_card).to have_summary_item("Payment status", "Authorised for payment at #{statement.marked_as_paid_at.in_time_zone("London").strftime("%-I:%M%P on %-e %b %Y")}")
  end

  it "shows the statement summary" do
    expect(subject).to have_component(NpqSeparation::Admin::StatementSummaryComponent.new(statement:))
  end

  it "shows adjustments" do
    expect(subject).to have_component(NpqSeparation::Admin::AdjustmentsTableComponent.new(adjustments: statement.adjustments, show_total: true))
  end

  it "shows the course finance details" do
    expect(subject).to have_component(NpqSeparation::Admin::CoursePaymentOverviewComponent.new(contract:))
  end

  it "shows the standalone payments details" do
    expect(subject).to have_component(NpqSeparation::Admin::CoursePaymentOverviewComponent.new(contract: special_contract))
  end

  it "shows the contract finance details" do
    expect(rendered).to have_table rows: [
      [contract.course.name, contract.contract_template.recruitment_target, number_to_currency(contract.contract_template.per_participant), ""],
    ]
  end
end
