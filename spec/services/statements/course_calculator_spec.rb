# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::CourseCalculator do
  subject { calculator }

  let(:calculator)     { described_class.new(contract:) }
  let(:cohort)         { create(:cohort, :current) }
  let(:course)         { create(:course, :leading_literacy) }
  let(:schedule)       { course.schedule_for(cohort:) }
  let(:statement)      { create(:statement, :next_output_fee, cohort:) }
  let(:paid_statement) { create(:statement, :paid, lead_provider:) }
  let(:lead_provider)  { statement.lead_provider }
  let(:application)    { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:) }
  let!(:contract)      { create(:contract, course:, statement:) }

  before do
    create(:schedule, :npq_leadership_autumn, cohort:)
    create(:schedule, :npq_specialist_autumn, cohort:)
  end

  describe "#billable_declarations_count_for_declaration_type" do
    %i[started retained completed].each do |declaration_type|
      let(declaration_type) { subject.billable_declarations_count_for_declaration_type(declaration_type.to_s) }
    end

    before do
      %w[started retained-1 retained-2 completed].each do |declaration_type|
        create_list(:declaration, 2, state: :eligible, declaration_type:, course:, lead_provider:, cohort:, statement:)
      end
    end

    it "can count different declaration types", :aggregate_failures do
      expect(started).to be(2)
      expect(retained).to be(4)
      expect(completed).to be(2)
    end

    context "when there are multiple declarations from same user and same type" do
      before do
        user = create(:user)
        Declaration.find_each { _1.application.update!(user:) }
      end

      it "they are counted once per user", :aggregate_failures do
        expect(started).to be(1)
        expect(retained).to be(2)
        expect(completed).to be(1)
      end
    end
  end

  describe "#billable_declarations_count" do
    subject { calculator.billable_declarations_count }

    context "when there are zero declarations" do
      it { is_expected.to be_zero }
    end

    context "when there are billable declarations" do
      before do
        create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:)
      end

      it { is_expected.to be(1) }
    end

    context "when multiple declarations from same user and same type" do
      let(:declaration) { create(:declaration, :eligible, application:, course:, lead_provider:, cohort:, statement:) }

      before do
        create(:declaration, :eligible, course:, lead_provider:, cohort:, application:, statement:).tap do |d|
          d.application.update!(user: declaration.application.user)
        end
      end

      it "has two declarations" do
        expect(Declaration.count).to be(2)
        expect(calculator.statement.statement_items.count).to be(2)
      end

      it { is_expected.to be(1) }
    end

    context "when multiple declarations from same user of multiple types" do
      let(:started_declaration) { create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:) }
      let(:retained_1_declaration) do
        create(:declaration,
               :eligible,
               application: started_declaration.application,
               declaration_type: "retained-1",
               course:,
               lead_provider:,
               cohort:,
               statement:)
      end

      before do
        create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:).tap do |d|
          d.application.update!(user: started_declaration.application.user)
        end

        create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:).tap do |d|
          d.application.update!(user: retained_1_declaration.application.user)
        end
      end

      it { is_expected.to be(2) }
    end
  end

  describe "#refundable_declarations_count" do
    context "when there are zero declarations" do
      it do
        expect(subject.refundable_declarations_count).to be_zero
      end
    end

    context "when there are refundable declarations" do
      before do
        create(:declaration, :awaiting_clawback, course:, lead_provider:, cohort:, statement:, paid_statement:)
      end

      it "is counted" do
        expect(subject.refundable_declarations_count).to be(1)
      end
    end
  end

  describe "#refundable_declarations_by_type_count" do
    before do
      create(:declaration, :awaiting_clawback, course:, lead_provider:, cohort:, statement:, paid_statement:)
      create_list(:declaration, 2, :awaiting_clawback, declaration_type: "retained-1", course:, lead_provider:, cohort:, statement:, paid_statement:)
      create_list(:declaration, 3, :awaiting_clawback, declaration_type: "retained-2", course:, lead_provider:, cohort:, statement:, paid_statement:)
    end

    it "returns counts of refunds by type" do
      expected = {
        "started" => 1,
        "retained-1" => 2,
        "retained-2" => 3,
      }

      expect(subject.refundable_declarations_by_type_count).to eql(expected)
    end
  end

  describe "#not_eligible_declarations" do
    context "when there are voided declarations" do
      before do
        create(:declaration, :voided, course:, lead_provider:, cohort:, statement:)
      end

      it "is counted" do
        expect(subject.not_eligible_declarations_count).to be(1)
      end
    end
  end

  describe "#declaration_count_for_milestone" do
    subject { calculator.declaration_count_for_declaration_type("started") }

    context "when there are no declarations" do
      it { is_expected.to be_zero }
    end

    context "when there are declarations" do
      before do
        create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:)
      end

      it { is_expected.to be(1) }
    end

    context "when there are multiple declarations from same user and same type" do
      let(:declaration) { create(:declaration, :eligible, course:, lead_provider:, statement:) }

      before do
        create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:).tap do |d|
          d.application.update!(user: declaration.application.user)
        end
      end

      it { is_expected.to be(1) }
    end
  end

  describe "#monthly_service_fees" do
    subject { calculator.monthly_service_fees }

    before do
      contract.contract_template.update!(monthly_service_fee:)
    end

    context "when monthly_service_fee on contract set to nil" do
      let(:monthly_service_fee) { nil }

      it { is_expected.to match_bigdecimal(BigDecimal("0.1212631578947368421052631578947368421064e4")) }
    end

    context "when monthly_service_fee present on contract" do
      let(:monthly_service_fee) { 5432.10 }

      it { is_expected.to eql(monthly_service_fee) }
    end

    context "when monthly_service_fee on contract set to 0.0" do
      let(:monthly_service_fee) { 0.0 }

      it { is_expected.to eql(monthly_service_fee) }
    end
  end

  describe "#service_fees_per_participant" do
    subject { calculator.service_fees_per_participant }

    before do
      contract.contract_template.update!(monthly_service_fee:, recruitment_target: 438)
    end

    context "when monthly_service_fee on contract set to nil" do
      let(:monthly_service_fee) { nil }

      it { is_expected.to match_bigdecimal(BigDecimal("0.16842105263157894736842105263157894737e2")) }
    end

    context "when monthly_service_fee present on contract" do
      let(:monthly_service_fee) { 5432.10 }

      it { is_expected.to match_bigdecimal(BigDecimal("0.12402054794520547945205479452054794521e2")) }
    end
  end

  describe "#course_has_targeted_delivery_funding?" do
    subject { calculator.course_has_targeted_delivery_funding? }

    let(:cohort) { create(:cohort, :has_targeted_delivery_funding) }
    let(:statement) { create(:statement, :has_targeted_delivery_funding, :next_output_fee, cohort:) }

    context "with early headship coaching offer" do
      let(:course) { create(:course, :early_headship_coaching_offer) }

      it { is_expected.to be false }
    end

    context "with additional support offer" do
      let(:course) { create(:course, :additional_support_offer) }

      it { is_expected.to be false }
    end

    context "with leadership course" do
      let(:course) { create(:course, :early_years_leadership) }

      it { is_expected.to be true }
    end
  end

  describe "#targeted_delivery_funding_declarations_count" do
    subject { calculator.targeted_delivery_funding_declarations_count }

    let(:application) do
      create(
        :application,
        :accepted,
        :eligible_for_funding,
        course:,
        lead_provider:,
        cohort:,
        eligible_for_funding: true,
        targeted_delivery_funding_eligibility: true,
      )
    end

    context "when there are zero declarations" do
      it { is_expected.to be_zero }
    end

    context "when there are targeted delivery funding declarations" do
      let(:cohort) { create(:cohort, :has_targeted_delivery_funding) }
      let(:statement) { create(:statement, :has_targeted_delivery_funding, :next_output_fee, cohort:) }

      before do
        create(:declaration, :eligible, course:, lead_provider:, application:, cohort:, statement:)
      end

      it { is_expected.to be(1) }
    end

    context "when multiple declarations from same user of one type" do
      let(:cohort) { create(:cohort, :has_targeted_delivery_funding) }
      let(:statement) { create(:statement, :has_targeted_delivery_funding, :next_output_fee, cohort:) }

      let(:application) do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          :with_declaration,
          course:,
          lead_provider:,
          eligible_for_funding: true,
          targeted_delivery_funding_eligibility: true,
          cohort:,
        )
      end

      before do
        create(:statement_item, declaration: application.declarations.first, statement:)
        create(:declaration, :payable, course:, lead_provider:, declaration_type: "retained-1", cohort:, statement:, application: create(:application, user: application.user))
      end

      it "has two declarations" do
        expect(Declaration.count).to be(2)
        expect(calculator.statement.statement_items.count).to be(2)
      end

      it { is_expected.to be(1) }
    end
  end

  describe "#targeted_delivery_funding_refundable_declarations_count" do
    subject { calculator.targeted_delivery_funding_refundable_declarations_count }

    let(:cohort) { create(:cohort, :has_targeted_delivery_funding) }
    let(:statement) { create(:statement, :has_targeted_delivery_funding, :next_output_fee, cohort:) }

    before { application.update! targeted_delivery_funding_eligibility: true }

    context "when there are zero declarations" do
      it { is_expected.to be_zero }
    end

    context "when there are targeted delivery funding refundable declarations" do
      before do
        create :declaration, :awaiting_clawback, course:, lead_provider:, application:, cohort:, statement:, paid_statement:
      end

      it { is_expected.to be(1) }
    end
  end

  describe "#allowed_declaration_types" do
    let(:course_group) { course.course_group }

    before do
      course_group.schedules.destroy_all
      create(:schedule, course_group:, cohort:, allowed_declaration_types: %w[started retained-1])
      create(:schedule, course_group:, cohort:, allowed_declaration_types: %w[retained-1 completed])
    end

    it "is derived from schedules" do
      expect(subject.allowed_declaration_types).to eql(%w[started retained-1 completed])
    end
  end

  describe "#output_payment" do
    let(:application) { create(:application, :with_declaration, course:) }

    before do
      create(:statement_item, declaration: application.declarations.first, statement:)
    end

    it "is a hash" do
      expect(subject.output_payment).to eq(
        {
          participants: 1,
          per_participant: 160,
          subtotal: 160,
        },
      )
    end
  end

  describe "#clawback_payment" do
    it "is a number" do
      expect(subject.clawback_payment).to be_a(Numeric)
    end
  end

  describe "#course_total" do
    it "includes monthly_service_fees" do
      expect {
        contract.contract_template.update!(monthly_service_fee: 10)
      }.to change(subject, :course_total).by(10)
    end

    {
      output_payment_subtotal: 10,
      clawback_payment: -10,
      targeted_delivery_funding_subtotal: 10,
      targeted_delivery_funding_refundable_subtotal: -10,
    }.each do |method, stubbed_value|
      it "includes #{method}" do
        expect {
          allow(calculator).to receive(method).and_return(stubbed_value)
        }.to change(subject, :course_total).by(10)
      end
    end
  end

  describe "#expected_output_payment_subtotal" do
    let(:expected_declarations_count) { 5 }

    it "returns the expected output payment subtotal for a given expected declarations count" do
      expect(subject.expected_output_payment_subtotal(expected_declarations_count)).to eq(expected_declarations_count * 160)
    end
  end
end
