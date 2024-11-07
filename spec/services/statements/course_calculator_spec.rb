# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::CourseCalculator do
  let!(:cohort) { Cohort.current rescue create(:cohort, :current) }
  let!(:leadership_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }
  let!(:specialist_schedule) { create(:schedule, :npq_specialist_autumn, cohort:) }

  let(:course)              { create(:course, :leading_literacy) }
  let(:schedule)            { course.schedule_for(cohort:) }
  let(:statement)           { create(:statement, :next_output_fee, cohort:) }
  let(:lead_provider)       { statement.lead_provider }
  let(:application)         { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:) }
  let!(:contract)           { create(:contract, course:, statement:) }

  subject { described_class.new(statement:, contract:) }

  describe "#billable_declarations_count_for_declaration_type" do
    before do
      travel_to statement.deadline_date do
        %w[started retained-1 retained-2 completed].flat_map do |declaration_type|
          create_list(:declaration, 2, state: :eligible, declaration_type:, course:, lead_provider:, cohort:, statement:)
        end
      end
    end

    it "can count different declaration types", :aggregate_failures do
      expect(subject.billable_declarations_count_for_declaration_type("started")).to eql(2)
      expect(subject.billable_declarations_count_for_declaration_type("retained")).to eql(4)
      expect(subject.billable_declarations_count_for_declaration_type("completed")).to eql(2)
    end

    context "when there are multiple declarations from same user and same type" do
      before do
        user = create(:user)
        Declaration.find_each { _1.application.update!(user:) }
      end

      it "they are counted once per user", :aggregate_failures do
        expect(subject.billable_declarations_count_for_declaration_type("started")).to eql(1)
        expect(subject.billable_declarations_count_for_declaration_type("retained")).to eql(2)
        expect(subject.billable_declarations_count_for_declaration_type("completed")).to eql(1)
      end
    end
  end

  describe "#billable_declarations_count" do
    context "when there are zero declarations" do
      it do
        expect(subject.billable_declarations_count).to be_zero
      end
    end

    context "when there are billable declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:)
        end
      end

      it "is counted" do
        expect(subject.billable_declarations_count).to eql(1)
      end
    end

    context "when multiple declarations from same user and same type" do
      let(:declaration) { create(:declaration, :eligible, application:, course:, lead_provider:, cohort:, statement:) }

      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, course:, lead_provider:, cohort:, application:, statement:).tap do |d|
            d.application.update!(user: declaration.application.user)
          end
        end
      end

      it "is counted once" do
        expect(subject.billable_declarations_count).to eql(1)
      end
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
        travel_to statement.deadline_date do
          create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:).tap do |d|
            d.application.update!(user: started_declaration.application.user)
          end

          create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:).tap do |d|
            d.application.update!(user: retained_1_declaration.application.user)
          end
        end
      end

      it "counts each type once" do
        expect(subject.billable_declarations_count).to eql(2)
      end
    end
  end

  describe "#refundable_declarations_count" do
    context "when there are zero declarations" do
      it do
        expect(subject.refundable_declarations_count).to be_zero
      end
    end

    context "when there are refundable declarations" do
      let!(:to_be_awaiting_clawed_back) do
        paid_statement = create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:)
        travel_to paid_statement.deadline_date do
          create(:declaration, :paid, course:, lead_provider:, cohort:, statement: paid_statement)
        end
      end

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration: to_be_awaiting_clawed_back).void
        end
      end

      it "is counted" do
        expect(subject.refundable_declarations_count).to eql(1)
      end
    end
  end

  describe "#refundable_declarations_by_type_count" do
    let(:eligible_statement) { create(:statement, :next_output_fee, :paid, deadline_date: statement.deadline_date - 1.month, lead_provider:) }

    before do
      create(:declaration, :eligible, :paid, course:, lead_provider:, cohort:, statement: eligible_statement)
      create_list(:declaration, 2, :eligible, :paid, declaration_type: "retained-1", course:, lead_provider:, cohort:, statement: eligible_statement)
      create_list(:declaration, 3, :eligible, :paid, declaration_type: "retained-2", course:, lead_provider:, cohort:, statement: eligible_statement)

      travel_to statement.deadline_date do
        Declaration.find_each { Declarations::Void.new(declaration: _1).void }
      end
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
        travel_to statement.deadline_date do
          d = create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:)
          Declarations::Void.new(declaration: d).void
        end
      end

      it "is counted" do
        expect(subject.not_eligible_declarations_count).to eql(1)
      end
    end
  end

  describe "#declaration_count_for_milestone" do
    context "when there are no declarations" do
      it do
        expect(subject.declaration_count_for_declaration_type('started')).to be_zero
      end
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:)
        end
      end

      it do
        expect(subject.declaration_count_for_declaration_type('started')).to eql(1)
      end
    end

    context "when there are multiple declarations from same user and same type" do
      let(:declaration) { create(:declaration, :eligible, course:, lead_provider:, statement:) }

      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, course:, lead_provider:, cohort:, statement:).tap do |d|
            d.application.update!(user: declaration.application.user)
          end
        end
      end

      it "is counted once" do
        expect(subject.declaration_count_for_declaration_type('started')).to eql(1)
      end
    end
  end

  describe "#monthly_service_fees" do
    before do
      contract.contract_template.update!(monthly_service_fee:)
    end

    context "when monthly_service_fee on contract set to nil" do
      let(:monthly_service_fee) { nil }

      it "returns calculated service fee" do
        expect(subject.monthly_service_fees).to eql(BigDecimal("0.1212631578947368421052631578947368421064e4"))
      end
    end

    context "when monthly_service_fee present on contract" do
      let(:monthly_service_fee) { 5432.10 }

      it "returns monthly_service_fee from contract" do
        expect(subject.monthly_service_fees).to eql(monthly_service_fee)
      end
    end

    context "when monthly_service_fee on contract set to 0.0" do
      let(:monthly_service_fee) { 0.0 }

      it "returns zero monthly_service_fee from contract" do
        expect(subject.monthly_service_fees).to eql(monthly_service_fee)
      end
    end
  end

  describe "#service_fees_per_participant" do
    before do
      contract.contract_template.update!(monthly_service_fee:, recruitment_target: 438)
    end

    context "when monthly_service_fee present on contract" do
      let(:monthly_service_fee) { nil }

      it "returns calculated service_fees_per_participant" do
        expect(subject.service_fees_per_participant).to eql(BigDecimal("0.16842105263157894736842105263157894737e2"))
      end
    end

    context "when monthly_service_fee present on contract" do
      let(:monthly_service_fee) { 5432.10 }

      it "returns value calulated from monthly_service_fee from contract" do
        expected = BigDecimal("0.12402054794520547945205479452054794521e2")

        expect(subject.service_fees_per_participant).to eql(expected)
      end
    end
  end

  describe "#course_has_targeted_delivery_funding?" do
    context "Early headship coaching offer" do
      let!(:course) { create(:course, :early_headship_coaching_offer) }

      it do
        expect(subject.course_has_targeted_delivery_funding?).to be false
      end
    end

    context "Additional support offer" do
      let!(:course) { create(:course, :additional_support_offer) }

      it do
        expect(subject.course_has_targeted_delivery_funding?).to be false
      end
    end

    context "Leadership course" do
      let!(:course) { create(:course, :early_years_leadership) }

      it do
        expect(subject.course_has_targeted_delivery_funding?).to be true
      end
    end
  end

  describe "#targeted_delivery_funding_declarations_count" do
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
      it do
        expect(subject.targeted_delivery_funding_declarations_count).to be_zero
      end
    end

    context "when there are targeted delivery funding declarations" do
      before do
        travel_to statement.deadline_date do
          create(:declaration, :eligible, course:, lead_provider:, application:, cohort:, statement:)
        end
      end

      it "is counted" do
        expect(subject.targeted_delivery_funding_declarations_count).to eql(1)
      end
    end

    context "when multiple declarations from same user of one type" do
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
          cohort:
        )
      end

      before do
        travel_to statement.deadline_date do
          create(:statement_item, declaration: application.declarations.first, statement:)
          create(:declaration, course:, lead_provider:, declaration_type: "retained-1", cohort:, statement:, application: create(:application, user: application.user))
        end
      end

      it "has two declarations" do
        expect(Declaration.count).to eql(2)
        expect(subject.statement.statement_items.count).to eql(2)
      end

      it "has one targeted delivery funding declaration" do
        expect(subject.targeted_delivery_funding_declarations_count).to eql(1)
      end
    end
  end

  describe "#targeted_delivery_funding_refundable_declarations_count" do
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
      it do
        expect(subject.targeted_delivery_funding_refundable_declarations_count).to be_zero
      end
    end

    context "when there are targeted delivery funding refundable declarations" do
      let!(:to_be_awaiting_clawed_back) do
        output_statement = create(:statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, lead_provider:)
        travel_to output_statement.deadline_date do
          create(:declaration, :paid, course:, lead_provider:, application:, cohort:, statement:)
        end
      end

      before do
        travel_to statement.deadline_date do
          Declarations::Void.new(declaration: to_be_awaiting_clawed_back).void
        end
      end

      it "has one targeted delivery funding refundable declaration" do
        expect(subject.targeted_delivery_funding_refundable_declarations_count).to eql(1)
      end
    end
  end

  describe "#output_payment" do
    it "is a hash" do
      expect(subject.output_payment).to be_a(Hash)
    end
  end

  describe "#clawback_payment" do
    it "is a number" do
      expect(subject.clawback_payment).to be_a(Numeric)
    end
  end
end
