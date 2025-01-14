require "rails_helper"

RSpec.describe NpqSeparation::Admin::CoursePaymentOverviewComponent, type: :component do
  subject { render_inline component }

  let(:component) { described_class.new(contract:) }
  let(:calculator) { ::Statements::CourseCalculator.new(contract:) }
  let(:statement) { create(:statement) }
  let(:paid_statement) { create(:statement, :paid) }
  let(:course) { create(:course, :senior_leadership) }
  let(:contract) { create(:contract, course:, statement:) }

  before do
    create :schedule, :npq_leadership_autumn
    create :schedule, :npq_leadership_spring

    create_list(:declaration, 2, :eligible, declaration_type: "started", course:, statement:)
    create_list(:declaration, 3, :eligible, declaration_type: "retained-1", course:, statement:)
    create(:declaration, :eligible, declaration_type: "completed", course:, statement:)
  end

  it { is_expected.to have_css "h2", text: contract.course.name }

  describe "counts" do
    it { is_expected.to have_text(/Started\s+2/) }
    it { is_expected.to have_text(/Retained 1\s+3/) }
    it { is_expected.to have_text(/Retained 2\s+0/) }
    it { is_expected.to have_text(/Completed\s+1/) }
    it { is_expected.to have_text(/#{t(".total_declarations")}\s+#{calculator.billable_declarations_count}/) }
    it { is_expected.to have_text(/#{t(".total_not_eligible_for_funding")}\s+#{calculator.not_eligible_declarations_count}/) }
  end

  describe "total" do
    it { is_expected.to have_css ".govuk-body", text: /#{t(".course_total")}\s+£#{calculator.course_total}/ }
  end

  describe "itemisation" do
    it { is_expected.to have_css "thead th", text: t(".payment_type") }
    it { is_expected.to have_css "thead th", text: t(".participants") }
    it { is_expected.to have_css "thead th", text: t(".payment_per_participant") }
    it { is_expected.to have_css "thead th", text: t(".total") }

    it { is_expected.to have_css "tr:nth-child(1) th", text: t(".output_payment") }
    it { is_expected.to have_css "tr:nth-child(1) td", text: calculator.billable_declarations_count }
    it { is_expected.to have_css "tr:nth-child(1) td", text: "£#{calculator.output_payment_per_participant}" }
    it { is_expected.to have_css "tr:nth-child(1) td", text: "£#{calculator.output_payment_subtotal}" }

    context "with no refundable declarations" do
      it { is_expected.not_to have_css "tr:nth-child(2) td", text: "Clawbacks" }
    end

    context "with refundable declarations" do
      before do
        create_list(:declaration, 2, :awaiting_clawback, course:, statement:, paid_statement:)
      end

      it { is_expected.to have_css "tr:nth-child(2) th", text: "Clawbacks - Started" }
      it { is_expected.to have_css "tr:nth-child(2) td:nth-child(2)", text: "2" }
      it { is_expected.to have_css "tr:nth-child(2) td:nth-child(3)", text: "-£160" }
      it { is_expected.to have_css "tr:nth-child(2) td:nth-child(4)", text: "-£320" }
    end

    context "when course does not have targeted delivery funding" do
      before do
        allow_any_instance_of(::Statements::CourseCalculator).to receive(:course_has_targeted_delivery_funding?).and_return(false)
      end

      it { is_expected.not_to have_text t(".targeted_delivery_funding") }
    end

    context "when course has targeted delivery funding" do
      let(:refund_selector) { "tr:nth-child(4) th" }
      let(:refund_text) { "Clawbacks" }

      before do
        allow_any_instance_of(::Statements::CourseCalculator).to receive(:course_has_targeted_delivery_funding?).and_return(true)
      end

      it { is_expected.to have_css("tr:nth-child(2) th:nth-child(1)", text: t(".targeted_delivery_funding")) }
      it { is_expected.to have_css("tr:nth-child(2) td:nth-child(2)", text: calculator.targeted_delivery_funding_declarations_count) }
      it { is_expected.to have_css("tr:nth-child(2) td:nth-child(3)", text: "£#{calculator.targeted_delivery_funding_per_participant}") }
      it { is_expected.to have_css("tr:nth-child(2) td:nth-child(4)", text: "£#{calculator.targeted_delivery_funding_subtotal}") }

      context "and no refundable declarations" do
        it { is_expected.not_to have_css(refund_selector, text: refund_text) }
      end

      context "and refundable declarations" do
        before do
          application = create(:application, :eligible_for_funding, targeted_delivery_funding_eligibility: true, course:)
          create(:declaration, :awaiting_clawback, application:, statement:, paid_statement:)
        end

        it { is_expected.to have_css(refund_selector, text: refund_text) }
        it { is_expected.to have_css("tr:nth-child(4) td:nth-child(2)", text: calculator.targeted_delivery_funding_refundable_declarations_count) }
        it { is_expected.to have_css("tr:nth-child(4) td:nth-child(3)", text: "-£#{calculator.targeted_delivery_funding_per_participant}") }
        it { is_expected.to have_css("tr:nth-child(4) td:nth-child(4)", text: "-£#{calculator.targeted_delivery_funding_refundable_subtotal}") }
      end
    end

    context "when monthly service fees are zero" do
      before { contract.contract_template.update! monthly_service_fee: 0 }

      it { is_expected.not_to have_text t(".service_fee") }
    end

    context "when monthly service fees are not zero" do
      before { contract.contract_template.update! monthly_service_fee: 10 }

      it { is_expected.to have_css "tr:nth-child(3) th", text: t(".service_fee") }
      it { is_expected.to have_css "tr:nth-child(3) td", text: "£#{calculator.monthly_service_fees}" }
    end
  end
end
