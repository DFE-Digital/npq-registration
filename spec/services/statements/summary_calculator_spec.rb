# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::SummaryCalculator do
  let(:cohort) { create(:cohort, :current) }
  let(:lead_provider) { create :lead_provider }
  let(:statement) { create(:statement, lead_provider:, reconcile_amount: 0) }
  let(:application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:) }
  let(:declaration_type) { "started" }

  let!(:course) { create(:course, :leading_teaching) }
  let!(:contract) { create(:contract, course:, statement:) }
  let(:contract_template_monthly_service_fee) { nil }

  subject { described_class.new(statement:) }

  before do
    create(:schedule, :npq_leadership_autumn, cohort:)
    create(:schedule, :npq_specialist_autumn, cohort:)
  end

  describe "#total_payment" do
    let(:default_total) { BigDecimal("0.1212631578947368421052631578947368421064e4") }
    let(:expected_total_output_payment) { 160 }
    let(:expected_total_targeted_delivery_funding) { 100 }

    before { contract.contract_template.update! monthly_service_fee: contract_template_monthly_service_fee }

    context "when there is a positive reconcile_amount" do
      before { statement.update!(reconcile_amount: 1234) }

      it "increases total" do
        expect(subject.total_payment).to eq(default_total + 1234)
      end
    end

    context "when there is a negative reconcile_amount" do
      before { statement.update!(reconcile_amount: -1234) }

      it "descreases the total" do
        expect(subject.total_payment).to eq(default_total - 1234)
      end
    end

    context "when there are course output payments" do
      before { create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:) }

      it "adds the output payments to the total" do
        expect(subject.total_payment).to eq(default_total + expected_total_output_payment)
      end
    end

    context "when there are targeted delivery funding" do
      let(:application) do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          course:,
          lead_provider:,
          targeted_delivery_funding_eligibility: true,
        )
      end

      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, declaration_type:, application:, lead_provider:, statement:)
        end
      end

      it "adds the targeted delivery funding to the total" do
        expect(subject.total_payment).to eq(default_total + expected_total_output_payment + expected_total_targeted_delivery_funding)
      end
    end

    context "when there are clawbacks" do
      let(:application) do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          course:,
          lead_provider:,
          targeted_delivery_funding_eligibility: true,
        )
      end

      let!(:to_be_awaiting_clawed_back) do
        travel_to create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:).deadline_date do
          create(:declaration, :paid, declaration_type:, application:, lead_provider:, statement:)
        end
      end
      let(:expected_total_clawbacks) { 260 }

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration: to_be_awaiting_clawed_back).void
        end
      end

      it "deducts the clawbacks from the total" do
        expect(subject.total_payment).to eq(default_total + expected_total_output_payment + expected_total_targeted_delivery_funding - expected_total_clawbacks)
      end
    end

    context "when there are adjustments" do
      let!(:adjustment_1) { create(:adjustment, statement:, amount: 100) }
      let!(:adjustment_2) { create(:adjustment, statement:, amount: -50) }

      it "adds adjustments to the total" do
        expect(subject.total_payment).to eq(default_total + adjustment_1.amount + adjustment_2.amount)
      end
    end
  end

  describe "#total_starts" do
    context "when there are no declarations" do
      it { expect(subject.total_starts).to be_zero }
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, lead_provider:, application:, statement:)
        end
      end

      context "with a billable declaration" do
        it "counts them" do
          expect(subject.total_starts).to eq(1)
        end
      end
    end

    context "when there are clawbacks" do
      let!(:declaration) do
        travel_to(1.month.ago) { create(:declaration, :paid, lead_provider:, statement: paid_statement) }
      end
      let(:paid_statement)     { create(:statement, :paid, lead_provider:) }

      let!(:statement)         { create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:) }

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration:).void
        end
      end

      it "does not count them" do
        expect(statement.reload.statement_items.where(state: "awaiting_clawback")).to exist
        expect(subject.total_starts).to be_zero
      end
    end
  end

  describe "#total_completed" do
    let(:declaration_type) { "completed" }

    context "when there are no declarations" do
      it do
        expect(subject.total_completed).to be_zero
      end
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, declaration_type:, lead_provider:, application:, statement:)
        end
      end

      it "counts them" do
        expect(subject.total_completed).to eq(1)
      end
    end

    context "when there are clawbacks" do
      let(:paid_statement) { create(:statement, :paid, lead_provider:) }
      let!(:declaration) do
        travel_to paid_statement.deadline_date do
          create(:declaration, :paid, declaration_type:, lead_provider:, application:, cohort:, statement: paid_statement)
        end
      end
      let!(:statement) { create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:) }

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration:).void
        end
      end

      it "does not count them" do
        expect(statement.statement_items.where(state: "awaiting_clawback")).to exist
        expect(subject.total_completed).to be_zero
      end
    end
  end

  describe "#total_retained" do
    let(:declaration_type) { "retained-1" }

    context "when there are no declarations" do
      it do
        expect(subject.total_retained).to be_zero
      end
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, declaration_type: "retained-1", application:, lead_provider:, statement:)
        end
      end

      it "counts them" do
        expect(subject.total_retained).to eq(1)
      end
    end

    context "when there are clawbacks" do
      let(:paid_statement) { create(:statement, :paid, lead_provider:) }

      let!(:declaration) do
        travel_to paid_statement.deadline_date do
          create(:declaration, :paid, declaration_type: "retained-1", lead_provider:, application:, statement: paid_statement)
        end
      end
      let!(:statement) { create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:) }

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration:).void
        end
      end

      it "does not count them" do
        expect(statement.statement_items.where(state: "awaiting_clawback")).to exist
        expect(subject.total_retained).to be_zero
      end
    end
  end

  describe "#total_voided" do
    context "when there are no declarations" do
      it { expect(subject.total_voided).to be_zero }
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :voided, application:, lead_provider:, statement:)
        end
      end

      it "counts them" do
        expect(subject.total_voided).to eq(1)
      end
    end

    context "when there are multiple declarations for the same user" do
      before do
        user = create :user
        create(:declaration, :voided, lead_provider:, statement:, application: create(:application, user:))
        create(:declaration, :voided, lead_provider:, statement:, application: create(:application, user:))
        create(:declaration, :voided, lead_provider:, statement:)
      end

      it "counts them" do
        expect(subject.total_voided).to eq(2)
      end
    end
  end

  context "when there exists contracts over multiple cohorts" do
    let!(:cohort_2022) { create(:cohort, :next) }
    let!(:statement_2022) { create(:statement, lead_provider:, cohort: cohort_2022) }

    before do
      create(:contract, statement: statement_2022, course:)
      create(
        :declaration,
        :eligible,
        application:,
        statement: statement_2022,
      )
    end

    it "only includes declarations for the related cohort" do
      expect(described_class.new(statement:).total_starts).to be_zero
      expect(described_class.new(statement: statement_2022).total_starts).to be(1)
    end
  end

  describe "#total_targeted_delivery_funding" do
    context "with no declarations" do
      it do
        expect(subject.total_targeted_delivery_funding).to be_zero
      end
    end

    context "with declaration" do
      let(:declaration_type) { "started" }

      let(:application) do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          course:,
          lead_provider:,
          targeted_delivery_funding_eligibility: true,
        )
      end

      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, declaration_type:, application:, lead_provider:, statement:)
        end
      end

      it "returns total targeted delivery funding" do
        expect(subject.total_targeted_delivery_funding.to_f).to eq(100.0)
      end
    end
  end

  describe "#total_targeted_delivery_funding_refundable" do
    context "with no declarations" do
      it do
        expect(subject.total_targeted_delivery_funding_refundable).to be_zero
      end
    end

    context "with declaration" do
      let(:declaration_type) { "started" }

      let(:application) do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          course:,
          lead_provider:,
          targeted_delivery_funding_eligibility: true,
        )
      end

      let!(:to_be_awaiting_clawed_back) do
        travel_to create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:).deadline_date do
          create(:declaration, :paid, declaration_type:, application:, lead_provider:)
        end
      end

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration: to_be_awaiting_clawed_back).void
        end
      end

      it "returns total targeted delivery funding refundable" do
        expect(subject.total_targeted_delivery_funding_refundable.to_f).to eq(100.0)
      end
    end
  end

  describe "#total_clawbacks" do
    let(:application) do
      create(
        :application,
        :accepted,
        :eligible_for_funding,
        course:,
        lead_provider:,
        eligible_for_funding: true,
        targeted_delivery_funding_eligibility: true,
      )
    end

    let!(:to_be_awaiting_clawed_back) do
      travel_to create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:).deadline_date do
        create(:declaration, :paid, declaration_type:, application:, lead_provider:, statement:)
      end
    end

    before do
      travel_to statement.deadline_date do
        Declarations::Void.new(declaration: to_be_awaiting_clawed_back).void
      end
    end

    it "returns total clawbacks" do
      expect(subject.clawback_payments.to_f).to eq(160.0)
      expect(subject.total_targeted_delivery_funding_refundable.to_f).to eq(100.0)
      expect(subject.total_clawbacks.to_f).to eq(160.0 + 100.0)
    end
  end

  describe "#total_adjustments" do
    before do
      create(:adjustment, statement:, amount: 100)
      create(:adjustment, statement:, amount: 200)
      create(:adjustment, amount: 400)
    end

    it "returns total adjustments" do
      expect(subject.total_adjustments.to_f).to eq(300)
    end
  end

  describe "Contract with special_course" do
    let!(:maths_course) { create(:course, :leading_primary_mathmatics) }
    let!(:leading_maths_contract) do
      create(
        :contract,
        statement:,
        course: maths_course,
      )
    end

    before do
      travel_to statement.deadline_date do
        create_list(:declaration, 3, :eligible, course:, lead_provider:, statement:)
        create_list(:declaration, 7, :eligible, course: maths_course, lead_provider:, statement:)
      end
    end

    context "when leading_maths_contract has special_course is false" do
      it "totals all course types" do
        expect(Contract.count).to be(2)
        expect(subject.total_starts.to_f).to eq(10)
        expect(subject.total_output_payment.to_f).to eq(160.0 * 10)
      end
    end

    context "when leading_maths_contract has special_course is true" do
      before do
        leading_maths_contract.contract_template.update!(special_course: true)
      end

      it "totals only totals course types that are not special" do
        expect(Contract.count).to be(2)
        expect(subject.total_starts.to_f).to eq(3)
        expect(subject.total_output_payment.to_f).to eq(160.0 * 3)
      end
    end
  end
end
