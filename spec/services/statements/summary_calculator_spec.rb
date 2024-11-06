# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::SummaryCalculator do
  # let(:cohort)              { Cohort.current || create(:cohort, :current) }
  let(:cohort)              { Cohort.current rescue create(:cohort, :current) }
  # let(:cpd_lead_provider)   { create(:cpd_lead_provider, :with_npq_lead_provider) }
  # let(:npq_lead_provider)   { cpd_lead_provider.npq_lead_provider }
  let(:lead_provider)       { create :lead_provider }
  # let(:statement)           { create(:npq_statement, cpd_lead_provider:) }
  let(:statement)           { create(:statement, lead_provider:) }
  # let(:participant_profile) { create(:npq_application, :accepted, :eligible_for_funding, npq_course:, npq_lead_provider:).profile }
  let(:application)         { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:) }
  # let(:milestone)           { participant_profile.schedule.milestones.find_by!(declaration_type:) }
  let(:declaration_type)    { "started" }

  # let!(:npq_leadership_schedule) { create(:npq_leadership_schedule, cohort:) }
  # let!(:npq_specialist_schedule) { create(:npq_specialist_schedule, cohort:) }
  # let!(:npq_course)              { create(:npq_leadership_course, identifier: "npq-leading-teaching") }
  let!(:leadership_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }
  let!(:specialist_schedule) { create(:schedule, :npq_specialist_autumn, cohort:) }
  let!(:course)              { create(:course, :early_years_leadership) }

  subject { described_class.new(statement:) }

  describe "#total_payment" do
    # let!(:contract) { create(:npq_contract, npq_lead_provider:, cohort:, monthly_service_fee: nil) }
    let!(:contract) { create(:contract, course:, statement:).tap { _1.contract_template.update! monthly_service_fee: nil } }
    let(:default_total) { BigDecimal("0.1212631578947368421052631578947368421064e4") }

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
  end

  describe "#total_starts" do
    let!(:contract) { create(:contract, course:, statement:) }

    context "when there are no declarations" do
      it { expect(subject.total_starts).to be_zero }
    end

    context "when there are declarations" do
      # let!(:participant_declaration) do
      let!(:declaration) do
        travel_to statement.deadline_date do
          # create(:npq_participant_declaration, :eligible, cpd_lead_provider:, participant_profile:)
          d = create(:declaration, :eligible, lead_provider:, application:)
          create(:statement_item, declaration: d, statement:)
        end
      end

      context "with a billable declaration" do
        it "counts them" do
          expect(subject.total_starts).to eq(1)
        end
      end
    end

    context "when there are clawbacks" do
      # let!(:participant_declaration) do
      let(:paid_statement)     { create(:statement, :paid, lead_provider:) }
      let!(:declaration) do
        # travel_to(1.month.ago) { create(:npq_participant_declaration, :paid, cpd_lead_provider:) }
        travel_to(1.month.ago) do
          create(:declaration, :paid, lead_provider:).tap do |d|
            create(:statement_item, :paid, declaration: d, statement: paid_statement)
          end
        end
      end
      # let(:paid_statement)     { Finance::Statement::NPQ::Paid.find_by!(cpd_lead_provider:) }

      # let!(:statement)         { create(:npq_statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, cpd_lead_provider:) }
      let!(:statement)         { create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:) }

      before do
        travel_to statement.deadline_date do
          # Finance::ClawbackDeclaration.new(participant_declaration).call
          Declarations::Void.new(declaration:).void
        end
      end

      it "does not count them" do
        # expect(statement.reload.statement_line_items.awaiting_clawback).to exist
        expect(statement.reload.statement_items.where(state: 'awaiting_clawback')).to exist
        expect(subject.total_starts).to be_zero
      end
    end
  end

  describe "#total_completed" do
    let!(:contract) { create(:contract, course:, statement:) }
    let(:declaration_type) { "completed" }

    context "when there are no declarations" do
      it do
        expect(subject.total_completed).to be_zero
      end
    end

    context "when there are declarations" do
      # let(:statement) { participant_declaration.statement_line_items.eligible.first.statement }
      # let(:statement) { declaration.statement_items.eligible.first.statement }

      # let!(:participant_declaration) do
      let!(:declaration) do
        # travel_to milestone.start_date do
        travel_to statement.deadline_date do
          # create(:npq_participant_declaration, :eligible, declaration_type:, cpd_lead_provider:, participant_profile:)
          create(:declaration, :eligible, declaration_type:, lead_provider:, application:).tap do |d|
            create(:statement_item, declaration: d, statement:)
          end
        end
      end

      it "counts them" do
        expect(subject.total_completed).to eq(1)
      end
    end

    context "when there are clawbacks" do
      let(:paid_statement)     { create(:statement, :paid, lead_provider:) }
      # let!(:participant_declaration) do
      let!(:declaration) do
        # travel_to milestone.start_date do
        travel_to paid_statement.deadline_date do
          # cohort = participant_profile.schedule.cohort
          create(:declaration, :paid, declaration_type:, lead_provider:, application:, cohort:).tap do |d|
            create(:statement_item, :paid, declaration: d, statement: paid_statement)
          end
        end
      end
      # let!(:previous_statement) { participant_declaration.statement_line_items.first.statement }
      # let!(:statement) { create(:npq_statement, :next_output_fee, deadline_date: previous_statement.deadline_date + 1.month, cpd_lead_provider:) }
      let!(:statement) { create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:) }
      before do
        travel_to statement.deadline_date do
          # Finance::ClawbackDeclaration.new(participant_declaration).call
          Declarations::Void.new(declaration:).void
        end
      end

      it "does not count them" do
        # expect(statement.statement_line_items.awaiting_clawback).to exist
        expect(statement.statement_items.where(state: 'awaiting_clawback')).to exist
        expect(subject.total_completed).to be_zero
      end
    end
  end

  describe "#total_retained" do
    let!(:contract) { create(:contract, course:, statement:) }
    let(:declaration_type) { "retained-1" }

    context "when there are no declarations" do
      it do
        expect(subject.total_retained).to be_zero
      end
    end

    context "when there are declarations" do
      # let!(:participant_declaration) do
      let!(:declaration) do
        travel_to statement.deadline_date do
          # create(:npq_participant_declaration, :eligible, course_identifier: npq_course.identifier, declaration_type: "retained-1", participant_profile:, cpd_lead_provider:)
          create(:declaration, :eligible, declaration_type: "retained-1", application:, lead_provider:).tap do |d|
            create(:statement_item, declaration: d, statement:)
          end
        end
      end
      # let(:statement) { participant_declaration.statement_line_items.eligible.first.statement }
      # let(:statement) { declaration.statement_items.eligible.first.statement }

      it "counts them" do
        expect(subject.total_retained).to eq(1)
      end
    end

    context "when there are clawbacks" do
      let(:paid_statement)     { create(:statement, :paid, lead_provider:) }

      # let!(:participant_declaration) do
      let!(:declaration) do
        # travel_to milestone.start_date do
        travel_to paid_statement.deadline_date do
          # create(:npq_participant_declaration, :paid, declaration_type: "retained-1", cpd_lead_provider:, participant_profile:)
          create(:declaration, :paid, declaration_type: "retained-1", lead_provider:, application:).tap do |d|
            create(:statement_item, :paid, declaration: d, statement: paid_statement)
          end
        end
      end
      # let(:previous_statement) { participant_declaration.statement_line_items.first.statement }
      # let!(:statement)         { create(:npq_statement, :next_output_fee, deadline_date: previous_statement.deadline_date + 1.month, cpd_lead_provider:) }
      let!(:statement)         { create(:statement, :next_output_fee, deadline_date: paid_statement.deadline_date + 1.month, lead_provider:) }
      before do
        travel_to statement.deadline_date do
          # Finance::ClawbackDeclaration.new(participant_declaration).call
          Declarations::Void.new(declaration:).void
        end
      end

      it "does not count them" do
        expect(statement.statement_items.where(state: 'awaiting_clawback')).to exist
        expect(subject.total_retained).to be_zero
      end
    end
  end

  describe "#total_voided" do
    let!(:contract) { create(:contract, course:, statement:) }

    context "when there are no declarations" do
      it { expect(subject.total_voided).to be_zero }
    end

    context "when there are declarations" do
      # let!(:participant_declaration) do
      let!(:declaration) do
        # travel_to milestone.start_date do
        travel_to statement.deadline_date do
          # create(:npq_participant_declaration, :voided, participant_profile:, cpd_lead_provider:)
          create(:declaration, :voided, application:, lead_provider:).tap do |d|
            create(:statement_item, declaration: d, statement:)
          end
        end
      end
      # let(:statement) { participant_declaration.statement_line_items.voided.first.statement }
      # let(:statement) { declaration.statement_items.voided.first.statement }

      it "counts them" do
        expect(subject.total_voided).to eq(1)
      end
    end

    context "when there are multiple declarations for the same application" do
      before do
        create(:declaration, :voided, application: application, lead_provider: lead_provider).tap { create(:statement_item, declaration: _1, statement:) }
        create(:declaration, :voided, application: application, lead_provider: lead_provider).tap { create(:statement_item, declaration: _1, statement:) }
        create(:declaration, :voided, lead_provider: lead_provider).tap { create(:statement_item, declaration: _1, statement:) }
      end

      it "counts them" do
        expect(subject.total_voided).to eq(2)
      end
    end
  end

  context "when there exists contracts over multiple cohorts" do
    # let!(:cohort_2022) { Cohort.next || create(:cohort, :next) }
    let!(:cohort_2022) { create(:cohort, :next) }
    # let!(:contract_2022) { create(:npq_contract, npq_lead_provider:, cohort: cohort_2022) }
    # let!(:statement_2022) { create(:npq_statement, cpd_lead_provider:, cohort: cohort_2022) }
    let!(:statement_2022) { create(:statement, lead_provider:, cohort: cohort_2022) }
    let!(:contract_2022) { create(:contract, statement: statement_2022, course:) }

    before do
      declaration = create(
        # :npq_participant_declaration,
        :declaration,
        # state: "eligible",
        :eligible,
        # course_identifier: npq_course.identifier,
        # npq_course:,
        application:,
      )

      create(:statement_item, declaration:, statement: statement_2022)

      # Finance::StatementLineItem.create!(
      #   statement: statement_2022,
      #   participant_declaration: declaration,
      #   state: declaration.state,
      # )
    end

    it "only includes declarations for the related cohort" do
      expect(described_class.new(statement:).total_starts).to be_zero
      expect(described_class.new(statement: statement_2022).total_starts).to eql(1)
    end
  end

  describe "#total_targeted_delivery_funding" do
    let!(:contract) { create(:contract, course:, statement:) }

    context "no declarations" do
      it do
        expect(subject.total_targeted_delivery_funding).to be_zero
      end
    end

    context "with declaration" do
      let(:declaration_type) { "started" }

      # let(:participant_profile) do
      let(:application) do
        create(
          # :npq_application,
          :application,
          :accepted,
          :eligible_for_funding,
          # npq_course:,
          course:,
          # npq_lead_provider:,
          lead_provider:,
          # eligible_for_funding: true,
          targeted_delivery_funding_eligibility: true,
        # ).profile
        )
      end

      # let!(:participant_declaration) do
      let!(:declaration) do
        # travel_to milestone.start_date do
        travel_to statement.deadline_date do
          # create(:npq_participant_declaration, :eligible, course_identifier: npq_course.identifier, declaration_type:, participant_profile:, cpd_lead_provider:)
          create(:declaration, :eligible, declaration_type:, application:, lead_provider:).tap do |d|
            create(:statement_item, declaration: d, statement:)
          end
        end
      end

      # let(:statement) { participant_declaration.statement_line_items.eligible.first.statement }

      it "returns total targeted delivery funding" do
        expect(subject.total_targeted_delivery_funding.to_f).to eq(100.0)
      end
    end
  end

  describe "#total_targeted_delivery_funding_refundable" do
    let!(:contract) { create(:contract, course:, statement:) }

    context "no declarations" do
      it do
        expect(subject.total_targeted_delivery_funding_refundable).to be_zero
      end
    end

    context "with declaration" do
      let(:declaration_type) { "started" }

      # let(:participant_profile) do
      let(:application) do
        create(
          # :npq_application,
          :application,
          :accepted,
          :eligible_for_funding,
          # npq_course:,
          course:,
          # npq_lead_provider:,
          lead_provider:,

          # eligible_for_funding: true,
          targeted_delivery_funding_eligibility: true,
        # ).profile
        )
      end

      let!(:to_be_awaiting_clawed_back) do
        # travel_to create(:npq_statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, cpd_lead_provider:).deadline_date do
        travel_to create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:).deadline_date do
          # create(:npq_participant_declaration, :paid, course_identifier: npq_course.identifier, declaration_type:, participant_profile:, cpd_lead_provider:)
          create(:declaration, :paid, declaration_type:, application:, lead_provider:)
        end
      end

      # let!(:participant_declaration) do
      let!(:declaration) do
        travel_to statement.deadline_date do
          # Finance::ClawbackDeclaration.new(to_be_awaiting_clawed_back).call
          Declarations::Void.new(declaration: to_be_awaiting_clawed_back).void
        end
      end

      it "returns total targeted delivery funding refundable" do
        expect(subject.total_targeted_delivery_funding_refundable.to_f).to eq(100.0)
      end
    end
  end

  describe "#total_clawbacks" do
    let!(:contract) { create(:contract, course:, statement:) }
    let(:declaration_type) { "started" }

    # let(:participant_profile) do
    let(:application) do
      create(
        # :npq_application,
        :application,
        :accepted,
        :eligible_for_funding,
        # npq_course:,
        # npq_lead_provider:,
        course:,
        lead_provider:,

        eligible_for_funding: true,
        targeted_delivery_funding_eligibility: true,
      # ).profile
      )
    end

    let!(:to_be_awaiting_clawed_back) do
      # travel_to create(:npq_statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, cpd_lead_provider:).deadline_date do
      travel_to create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:).deadline_date do
        # create(:npq_participant_declaration, :paid, course_identifier: npq_course.identifier, declaration_type:, participant_profile:, cpd_lead_provider:)
        create(:declaration, :paid, declaration_type:, application:, lead_provider:).tap do |d|
          create(:statement_item, :paid, declaration: d, statement:)
        end
      end
    end

    # let!(:participant_declaration) do
    let!(:declaration) do
      travel_to statement.deadline_date do
        # Finance::ClawbackDeclaration.new(to_be_awaiting_clawed_back).call
        Declarations::Void.new(declaration: to_be_awaiting_clawed_back).void
      end
    end

    it "returns total clawbacks" do
      expect(subject.clawback_payments.to_f).to eq(160.0)
      expect(subject.total_targeted_delivery_funding_refundable.to_f).to eq(100.0)
      expect(subject.total_clawbacks.to_f).to eq(160.0 + 100.0)
    end
  end

  describe "Contract with special_course" do
    # let!(:npq_maths_course) { create(:npq_leadership_course, identifier: "npq-leading-primary-mathematics") }
    let!(:maths_course) { create(:course, :leading_primary_mathmatics) }
    let!(:contract) { create(:contract, course:, statement:) }

    let!(:leading_maths_contract) do
      # npq_lead_provider.npq_contracts.find_by(
        # version: statement.contract_version,
        # cohort: statement.cohort,
        # course_identifier: npq_maths_course.identifier,
      create(
        :contract,
        statement: statement,
        course: maths_course,
      )
    end

    before do
      travel_to statement.deadline_date do
        # create_list(:npq_participant_declaration, 3, :eligible, npq_course:, cpd_lead_provider:)
        # create_list(:npq_participant_declaration, 7, :eligible, npq_course: npq_maths_course, cpd_lead_provider:)
        d = create_list(:declaration, 3, :eligible, course:, lead_provider:)
        d += create_list(:declaration, 7, :eligible, course: maths_course, lead_provider:)
        d.each { create(:statement_item, declaration: _1, statement:) }
      end
    end

    context "when leading_maths_contract has special_course is false" do
      it "totals all course types" do
        # expect(NPQContract.count).to eql(2)
        expect(Contract.count).to eql(2)
        expect(subject.total_starts.to_f).to eq(10)
        expect(subject.total_output_payment.to_f).to eq(160.0 * 10)
      end
    end

    context "when leading_maths_contract has special_course is true" do
      before do
        # leading_maths_contract.update!(special_course: true)
        leading_maths_contract.contract_template.update!(special_course: true)
      end

      it "totals only totals course types that are not special" do
        # expect(NPQContract.count).to eql(2)
        expect(Contract.count).to eql(2)
        expect(subject.total_starts.to_f).to eq(3)
        expect(subject.total_output_payment.to_f).to eq(160.0 * 3)
      end
    end
  end
end
