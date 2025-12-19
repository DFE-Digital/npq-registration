# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::SummaryCalculator do
  let(:cohort) { create(:cohort, :has_targeted_delivery_funding) }
  let(:other_cohort) { create(:cohort, :next) }
  let(:lead_provider) { create :lead_provider }
  let(:statement) { create(:statement, :next_output_fee, lead_provider:, reconcile_amount: 0, cohort:) }
  let(:application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:, cohort:) }
  let(:declaration_type) { "started" }

  let!(:course) { create(:course, :leading_teaching) }
  let!(:contract) { create(:contract, course:, statement:) }
  let(:contract_template_monthly_service_fee) { nil }

  subject(:summary_calculator) { described_class.new(statement:) }

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
        expect(subject.total_payment).to match_bigdecimal(default_total + 1234)
      end
    end

    context "when there is a negative reconcile_amount" do
      before { statement.update!(reconcile_amount: -1234) }

      it "descreases the total" do
        expect(subject.total_payment).to match_bigdecimal(default_total - 1234)
      end
    end

    context "when there are course output payments" do
      before { create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:) }

      it "adds the output payments to the total" do
        expect(subject.total_payment).to match_bigdecimal(default_total + expected_total_output_payment)
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
        expect(subject.total_payment).to match_bigdecimal(default_total + expected_total_output_payment + expected_total_targeted_delivery_funding)
      end
    end

    context "when there are clawbacks" do
      before do
        awaiting_clawback = travel_to 2.months.ago do
          application

          earlier_statement =
            create(:statement, :next_output_fee, lead_provider:, cohort: application.cohort)

          create(:declaration, :paid, declaration_type:, application:, lead_provider:, statement: earlier_statement)
        end

        travel_to 1.month.from_now do
          create(:statement, :next_output_fee, lead_provider:, cohort: application.cohort)
          Declarations::Void.new(declaration: awaiting_clawback).void || raise("Could not void")
        end
      end

      let :application do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          course:,
          lead_provider:,
          targeted_delivery_funding_eligibility: true,
        )
      end

      let(:expected_total_clawbacks) { 260 }

      it "deducts the clawbacks from the total" do
        expect(subject.total_payment)
          .to match_bigdecimal(default_total +
                               expected_total_output_payment +
                               expected_total_targeted_delivery_funding -
                               expected_total_clawbacks)
      end
    end

    context "when there are adjustments" do
      let!(:adjustment_1) { create(:adjustment, statement:, amount: 100) }
      let!(:adjustment_2) { create(:adjustment, statement:, amount: -50) }

      it "adds adjustments to the total" do
        expect(subject.total_payment).to match_bigdecimal(default_total + adjustment_1.amount + adjustment_2.amount)
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
      before do
        declaration = travel_to(1.month.ago) do
          create(:declaration, :paid, lead_provider:, statement: paid_statement, cohort:)
        end

        statement

        travel_to statement.deadline_date do
          Declarations::Void.new(declaration:).void || raise("Could not void")
        end
      end

      let(:paid_statement) { create(:statement, :paid, lead_provider:) }

      let :statement do
        create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:, cohort:)
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
      let(:paid_statement) { create(:statement, :paid, lead_provider:, cohort:) }
      let!(:declaration) do
        travel_to paid_statement.deadline_date do
          create(:declaration, :paid, declaration_type:, lead_provider:, application:, cohort:, statement: paid_statement)
        end
      end
      let!(:statement) { create(:statement, :next_output_fee, cohort:, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:) }

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
      let(:paid_statement) { create(:statement, :paid, lead_provider:, cohort:) }

      let!(:declaration) do
        travel_to paid_statement.deadline_date do
          create(:declaration, :paid, declaration_type: "retained-1", lead_provider:, application:, cohort:, statement: paid_statement)
        end
      end
      let!(:statement) { create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:, cohort:) }

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
        expect(subject.total_voided).to eq(3)
      end
    end
  end

  context "when there exists contracts over multiple cohorts" do
    let!(:cohort_2023) { create(:cohort, :next) }
    let!(:statement_2023) { create(:statement, lead_provider:, cohort: cohort_2023) }

    before do
      create(:contract, statement: statement_2023, course:)
      create(
        :declaration,
        :eligible,
        application:,
        statement: statement_2023,
      )
    end

    it "only includes declarations for the related cohort" do
      expect(described_class.new(statement:).total_starts).to be_zero
      expect(described_class.new(statement: statement_2023).total_starts).to be(1)
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
      before do
        application.schedule.update! applies_from: statement.deadline_date - 1.month
        earlier_statement = create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:)

        awaiting_clawback = travel_to(earlier_statement.deadline_date) do
          create(:declaration, :paid, declaration_type:, application:, lead_provider:, statement: earlier_statement)
        end

        travel_to statement.deadline_date do
          Declarations::Void.new(declaration: awaiting_clawback).void || raise("Could not void")
        end
      end

      let(:declaration_type) { "started" }

      let(:application) do
        create(
          :application,
          :accepted,
          :eligible_for_funding,
          course:,
          lead_provider:,
          targeted_delivery_funding_eligibility: true,
          cohort:,
        )
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
        cohort:,
      )
    end

    before do
      application.schedule.update! applies_from: statement.deadline_date - 1.month
      earlier_statement = create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:)

      awaiting_clawback = travel_to(earlier_statement.deadline_date) do
        create(:declaration, :paid, declaration_type:, application:, lead_provider:, statement:)
      end

      travel_to statement.deadline_date do
        Declarations::Void.new(declaration: awaiting_clawback).void || raise("Could not void")
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

  describe "#declaration_types" do
    let(:milestone_1) { create(:milestone, declaration_type: "started") }
    let(:milestone_2) { create(:milestone, declaration_type: "retained-1") }

    before do
      create(:milestone_statement, milestone: milestone_1, statement:)
      create(:milestone_statement, milestone: milestone_2, statement:)
    end

    it "returns milestone declaration types associated with the statement" do
      expect(subject.declaration_types).to match_array(%w[started retained-1])
    end
  end

  describe "applications and declarations" do
    let(:course) { leadership_course }
    let(:leadership_course) { create(:course, :senior_leadership) }
    let(:specialist_course) { create(:course, :leading_teaching) }
    let(:aso_course) { create(:course, :additional_support_offer) }
    let(:ehco_course) { create(:course, :early_headship_coaching_offer) }

    let(:retained_1_milestone) { create(:milestone, declaration_type: "retained-1", schedule: started_application.schedule) }
    let(:retained_2_milestone) { create(:milestone, declaration_type: "retained-2", schedule: leadership_retained_1_application.schedule) }

    let(:not_accepted_yet_application) { create(:application, :eligible_for_funding, course:, lead_provider:, cohort:) }
    let(:other_cohort_application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:, cohort: other_cohort) }

    # started applications
    let(:started_application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:, cohort:) }
    let(:withdrawn_started_application) { create(:application, :withdrawn, course:, lead_provider:, cohort:) }
    let(:deferred_started_application) { create(:application, :deferred, course:, lead_provider:, cohort:) }
    let(:application_with_eligible_declaration) { create(:application, :accepted, course:) }
    let(:application_with_other_declaration_type_declaration) { create(:application, :accepted, course:) }

    # retained-1 applications
    let(:leadership_retained_1_application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:, cohort:) }
    let(:specialist_leadership_retained_1_application) { create(:application, :accepted, :eligible_for_funding, course: specialist_course, lead_provider:, cohort:) }
    let(:aso_retained_1_application) { create(:application, :accepted, :eligible_for_funding, course: aso_course, lead_provider:, cohort:) }
    let(:withdrawn_leadership_retained_1_application) { create(:application, :withdrawn, course:, lead_provider:, cohort:) }
    let(:deferred_leadership_retained_1_application) { create(:application, :deferred, course:, lead_provider:, cohort:) }
    let(:aso_application_not_penultimate) { create(:application, :accepted, :eligible_for_funding, course: aso_course, lead_provider:, cohort:) }
    let(:withdrawn_specialist_leadership_retained_1_application) { create(:application, :withdrawn, course:, lead_provider:, cohort:) }
    let(:deferred_specialist_leadership_retained_1_application) { create(:application, :deferred, course:, lead_provider:, cohort:) }
    let(:ehco_application_not_penultimate) { create(:application, :accepted, :eligible_for_funding, course: ehco_course, lead_provider:, cohort:) }

    # retained-2 applications
    let(:leadership_retained_2_application) { create(:application, :accepted, :eligible_for_funding, course: leadership_course, lead_provider:, cohort:) }
    let(:withdrawn_leadership_retained_2_application) { create(:application, :withdrawn, :eligible_for_funding, course: leadership_course, lead_provider:, cohort:) }
    let(:deferred_leadership_retained_2_application) { create(:application, :deferred, :eligible_for_funding, course: leadership_course, lead_provider:, cohort:) }
    let(:ehco_retained_2_application) { create(:application, :accepted, :eligible_for_funding, course: ehco_course, lead_provider:, cohort:) }

    let(:accepted_applications) do
      [
        started_application,
        leadership_retained_1_application,
        aso_retained_1_application,
        specialist_leadership_retained_1_application,
        ehco_application_not_penultimate,
        aso_application_not_penultimate,
        leadership_retained_2_application,
        ehco_retained_2_application,
      ]
    end

    # declarations
    let(:eligible_declaration) { create(:declaration, :eligible, declaration_type: "started", application: application_with_eligible_declaration, course:, lead_provider:, cohort:, statement:) }
    let(:other_cohort_declaration) { create(:declaration, :eligible, declaration_type: "started", application: other_cohort_application, course:, lead_provider:, cohort: other_cohort, statement:) }
    let(:other_declaration_type_declaration) { create(:declaration, :eligible, declaration_type: "retained-1", application: application_with_other_declaration_type_declaration, course:, lead_provider:, cohort:, statement:) }

    # milestones
    let(:milestones_for_all_declaration_types) do
      create(:milestone, declaration_type: "retained-1", schedule: specialist_leadership_retained_1_application.schedule)
      create(:milestone, declaration_type: "retained-1", schedule: aso_retained_1_application.schedule)
      retained_1_milestone
      create(:milestone_statement, milestone: retained_1_milestone, statement:)
      create(:milestone, declaration_type: "retained-1", schedule: ehco_application_not_penultimate.schedule)
      retained_2_milestone
      create(:milestone_statement, milestone: retained_2_milestone, statement:)
      create(:milestone, declaration_type: "retained-2", schedule: ehco_retained_2_application.schedule)
      create(:milestone, declaration_type: "retained-2", schedule: aso_retained_1_application.schedule)
      completed_milestone = create(:milestone, declaration_type: "completed", schedule: specialist_leadership_retained_1_application.schedule)
      create(:milestone_statement, milestone: completed_milestone, statement:)
      create(:milestone, declaration_type: "completed", schedule: ehco_retained_2_application.schedule)
      create(:milestone, declaration_type: "completed", schedule: aso_retained_1_application.schedule)
      create(:milestone, declaration_type: "completed", schedule: leadership_retained_2_application.schedule)
    end

    let(:milestones_for_completed_declaration_type) do
      create(:milestone, declaration_type: "retained-1", schedule: specialist_leadership_retained_1_application.schedule)
      create(:milestone, declaration_type: "retained-1", schedule: aso_retained_1_application.schedule)
      create(:milestone, declaration_type: "retained-1", schedule: leadership_retained_1_application.schedule)
      create(:milestone, declaration_type: "retained-1", schedule: ehco_application_not_penultimate.schedule)
      create(:milestone, declaration_type: "retained-2", schedule: leadership_retained_2_application.schedule)
      create(:milestone, declaration_type: "retained-2", schedule: ehco_retained_2_application.schedule)
      create(:milestone, declaration_type: "retained-2", schedule: aso_retained_1_application.schedule)
      create(:milestone, declaration_type: "completed", schedule: specialist_leadership_retained_1_application.schedule)
      create(:milestone, declaration_type: "completed", schedule: ehco_retained_2_application.schedule)
      create(:milestone, declaration_type: "completed", schedule: aso_retained_1_application.schedule)
      create(:milestone, declaration_type: "completed", schedule: leadership_retained_2_application.schedule)
    end

    before do
      other_cohort_application
      not_accepted_yet_application

      # started declarations
      create(:declaration, declaration_type: "started", application: started_application, course:, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "started", application: withdrawn_started_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "started", application: deferred_started_application, lead_provider:, cohort:, statement:)

      # retained-1 declarations
      create(:declaration, declaration_type: "retained-1", application: leadership_retained_1_application, course:, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: withdrawn_leadership_retained_1_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: deferred_leadership_retained_1_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: aso_retained_1_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: specialist_leadership_retained_1_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: withdrawn_specialist_leadership_retained_1_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: deferred_specialist_leadership_retained_1_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: ehco_application_not_penultimate, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: aso_application_not_penultimate, lead_provider:, cohort:, statement:)

      # retained-2 declarations
      create(:declaration, declaration_type: "retained-2", application: leadership_retained_2_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-2", application: ehco_retained_2_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-2", application: aso_retained_1_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-2", application: withdrawn_leadership_retained_2_application, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-2", application: deferred_leadership_retained_2_application, lead_provider:, cohort:, statement:)

      travel_to statement.deadline_date do
        eligible_declaration
        create(:declaration, :voided, declaration_type: "started", course:, lead_provider:, cohort:, statement:)
        create(:declaration, :ineligible, declaration_type: "started", course:, lead_provider:, cohort:, statement:)
        other_cohort_declaration
        other_declaration_type_declaration
        create(:declaration, :voided, declaration_type: "retained-1", course:, lead_provider:, cohort:, statement:)
        create(:declaration, :ineligible, declaration_type: "retained-1", course:, lead_provider:, cohort:, statement:)
      end
    end

    describe "#expected_applications" do
      subject(:expected_applications) { summary_calculator.expected_applications(declaration_type) }

      context "when the milestone declaration type is: started" do
        let(:declaration_type) { "started" }

        it "returns the accepted applications for the statement's cohort" do
          expect(expected_applications).to match_array(Application.accepted.where(cohort: statement.cohort).all)
        end
      end

      context "when the milestone declaration type is: retained-1" do
        let(:declaration_type) { "retained-1" }

        before { retained_1_milestone }

        it "returns the started active applications in the statement's cohort" do
          expect(expected_applications).to contain_exactly(started_application)
        end
      end

      context "when the milestone declaration type is: retained-2" do
        let(:declaration_type) { "retained-2" }

        before { retained_2_milestone }

        it "returns the retained-1 active applications in the statement's cohort" do
          expect(expected_applications).to contain_exactly(leadership_retained_1_application)
        end
      end

      context "when the milestone declaration type is: completed" do
        let(:declaration_type) { "completed" }

        before { milestones_for_completed_declaration_type }

        it "returns the active applications that have penultimate declarations in the statement's cohort" do
          expect(expected_applications).to contain_exactly(
            specialist_leadership_retained_1_application, leadership_retained_2_application, ehco_retained_2_application, aso_retained_1_application
          )
        end
      end

      context "when the declaration type is nil" do
        let(:declaration_type) { nil }

        before { milestones_for_all_declaration_types }

        context "when there is a started milestone" do
          before do
            started_milestone = create(:milestone, declaration_type: "started", schedule: started_application.schedule)
            create(:milestone_statement, milestone: started_milestone, statement:)
          end

          it "returns the sum of all expected applications" do
            expect(expected_applications).to match_array(
              summary_calculator.expected_applications("started") +
              summary_calculator.expected_applications("retained-1") +
              summary_calculator.expected_applications("retained-2") +
              summary_calculator.expected_applications("completed"),
            )
          end
        end

        context "when there is not a started milestone" do
          it "returns the sum of all expected applications" do
            expect(expected_applications).to match_array(
              summary_calculator.expected_applications("retained-1") +
              summary_calculator.expected_applications("retained-2") +
              summary_calculator.expected_applications("completed"),
            )
          end
        end
      end
    end

    describe "#received_declarations" do
      it "returns the billable declarations for the statement of the given declaration type, in the given cohort" do
        expect(subject.received_declarations("started")).to contain_exactly(eligible_declaration)
      end

      context "when the declaration type is nil" do
        it "returns all billable declarations for the statement in the given cohort" do
          expect(subject.received_declarations).to contain_exactly(eligible_declaration, other_declaration_type_declaration)
        end
      end
    end
  end

  describe "Contract with special_course" do
    let!(:maths_course) { create(:course, :leading_primary_mathematics) }
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
