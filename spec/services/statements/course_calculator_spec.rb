# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::CourseCalculator do
  # let!(:cohort) { Cohort.current || create(:cohort, :current) }
  let!(:cohort) { Cohort.current rescue create(:cohort, :current) }
  # let!(:npq_leadership_schedule) { create(:npq_leadership_schedule, cohort:) }
  # let!(:npq_specialist_schedule) { create(:npq_specialist_schedule, cohort:) }
  let!(:leadership_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }
  let!(:specialist_schedule) { create(:schedule, :npq_specialist_autumn, cohort:) }

  let(:course)              { create(:course, :leading_literacy) }
  # let(:schedule)            { Course.schedule_for(course:, cohort:) }
  let(:schedule)            { course.schedule_for(cohort:) }
  # let(:statement)           { create(:npq_statement, :next_output_fee, deadline_date: schedule.milestones.find_by(declaration_type: "completed").start_date + 30.days, cohort:) }
  let(:statement)           { create(:statement, :next_output_fee, cohort:) }
  # let(:cpd_lead_provider)   { statement.cpd_lead_provider }
  # let(:npq_lead_provider)   { cpd_lead_provider.npq_lead_provider }
  let(:lead_provider)       { statement.lead_provider }
  # let(:participant_profile) { create(:npq_application, :accepted, :eligible_for_funding, course:, npq_lead_provider:).profile }
  let(:application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:) }
  # let!(:contract)           { create(:npq_contract, npq_lead_provider:, course_identifier: course.identifier, cohort:, monthly_service_fee: nil) }
  let!(:contract)           { create(:contract, course:, statement:) }
  subject { described_class.new(statement:, contract:) }

  describe "#billable_declarations_count_for_declaration_type" do
    before do
      travel_to statement.deadline_date do
        # create_list(:npq_participant_declaration, 6, :eligible, course:, declaration_type: %w[started retained-1 retained-2 completed].sample, cpd_lead_provider:, cohort:)
        declarations = %w[started retained-1 retained-2 completed].flat_map do |declaration_type|
          create_list(:declaration, 2, state: :eligible, declaration_type:, course:, lead_provider:, cohort:)
        end
        declarations.each { create(:statement_item, declaration: _1, statement:) }
      end
    end

    it "can count different declaration types", :aggregate_failures do
      # expect(subject.billable_declarations_count_for_declaration_type("started")).to eql(ParticipantDeclaration::NPQ.where(declaration_type: "started").count)
      # expect(subject.billable_declarations_count_for_declaration_type("retained")).to eql(ParticipantDeclaration::NPQ.where(declaration_type: %w[retained-1 retained-2]).count)
      # expect(subject.billable_declarations_count_for_declaration_type("completed")).to eql(ParticipantDeclaration::NPQ.where(declaration_type: "completed").count)
      expect(subject.billable_declarations_count_for_declaration_type("started")).to eql(2)
      expect(subject.billable_declarations_count_for_declaration_type("retained")).to eql(4)
      expect(subject.billable_declarations_count_for_declaration_type("completed")).to eql(2)
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
          # create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:, cohort:)
          declaration = create(:declaration, :eligible, course:, lead_provider:, cohort:)
          create(:statement_item, declaration:, statement:)
        end
      end

      it "is counted" do
        expect(subject.billable_declarations_count).to eql(1)
      end
    end

    context "when multiple declarations from same application of one type" do
      # let(:participant_declaration) { create(:npq_participant_declaration, :eligible, participant_profile:, course:, cpd_lead_provider:, cohort:) }
      let(:declaration) { create(:declaration, :eligible, application:, course:, lead_provider:, cohort:) }

      before do
        travel_to statement.deadline_date do
          # create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:, cohort:).tap do |pd|
          #   pd.update!(user: participant_declaration.user)
          # end
          create(:statement_item, declaration:, statement:)
          create(:declaration, :eligible, course:, lead_provider:, cohort:).tap do |pd|
            pd.update!(application:)
            create(:statement_item, declaration: pd, statement:)
          end
        end
      end

      it "is counted once" do
        expect(subject.billable_declarations_count).to eql(1)
      end
    end

    context "when multiple declarations from same application of multiple types" do
      # let(:started_participant_declaration)    { create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:, cohort:) }
      # let(:retained_1_participant_declaration) do
      #   create(:npq_participant_declaration,
      #          :eligible,
      #          participant_profile: started_participant_declaration.participant_profile,
      #          declaration_type: "retained-1",
      #          course:,
      #          cpd_lead_provider:,
      #          cohort:)
      # end

      # before do
      #   travel_to statement.deadline_date do
      #     create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:, cohort:).tap do |pd|
      #       pd.update!(user: started_participant_declaration.user)
      #     end

      #     create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:, cohort:).tap do |pd|
      #       pd.update!(user: retained_1_participant_declaration.user)
      #     end
      #   end
      # end

      let(:started_declaration)    { create(:declaration, :eligible, course:, lead_provider:, cohort:) }
      let(:retained_1_declaration) do
        create(:declaration,
               :eligible,
               application: started_declaration.application,
               declaration_type: "retained-1",
               course:,
               lead_provider:,
               cohort:)
      end

      before do
        travel_to statement.deadline_date do
          create(:statement_item, declaration: started_declaration, statement:)
          create(:statement_item, declaration: retained_1_declaration, statement:)

          create(:declaration, :eligible, course:, lead_provider:, cohort:).tap do |pd|
            pd.update!(application: started_declaration.application)
            create(:statement_item, declaration: pd, statement:)
          end

          create(:declaration, :eligible, course:, lead_provider:, cohort:).tap do |pd|
            pd.update!(application: retained_1_declaration.application)
            create(:statement_item, declaration: pd, statement:)
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
        # travel_to create(:npq_statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, cpd_lead_provider:).deadline_date do
        #   create(:npq_participant_declaration, :paid, course:, cpd_lead_provider:, cohort:)
        # end
        travel_to create(:statement, :next_output_fee, lead_provider:).deadline_date do
          create(:declaration, :paid, course:, lead_provider:, cohort:)
        end
      end
      before do
        travel_to statement.deadline_date do
          # Finance::ClawbackDeclaration.new(to_be_awaiting_clawed_back).call
          Declarations::Void.new(declaration: to_be_awaiting_clawed_back).void
        end
      end

      it "is counted" do
        expect(subject.refundable_declarations_count).to eql(1)
      end
    end
  end

  describe "#refundable_declarations_by_type_count" do
    # let(:eligible_statement)                  { create(:npq_statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, cpd_lead_provider:) }
    # let(:to_be_awaiting_claw_back_started)    { create(:npq_participant_declaration,         :eligible, course:, cpd_lead_provider:, cohort:) }
    # let(:to_be_awaiting_claw_back_retained_1) { create_list(:npq_participant_declaration, 2, :eligible, declaration_type: "retained-1", course:, cpd_lead_provider:, cohort:) }
    # let(:to_be_awaiting_claw_back_completed)  { create_list(:npq_participant_declaration, 3, :eligible, declaration_type: "retained-2", course:, cpd_lead_provider:, cohort:) }
    let(:eligible_statement)                  { create(:statement, :next_output_fee, state: 'paid', lead_provider:) }
    let(:to_be_awaiting_claw_back_started)    { create(:declaration, :eligible, state: 'paid', course:, lead_provider:, cohort:) }
    let(:to_be_awaiting_claw_back_retained_1) { create_list(:declaration, 2, :eligible, state: 'paid', declaration_type: "retained-1", course:, lead_provider:, cohort:) }
    let(:to_be_awaiting_claw_back_completed)  { create_list(:declaration, 3, :eligible, state: 'paid', declaration_type: "retained-2", course:, lead_provider:, cohort:) }
    let(:declarations) do
      [to_be_awaiting_claw_back_started] + to_be_awaiting_claw_back_retained_1 + to_be_awaiting_claw_back_completed
    end
    before do
      travel_to(eligible_statement.deadline_date) do
        to_be_awaiting_claw_back_started
        to_be_awaiting_claw_back_retained_1
        to_be_awaiting_claw_back_completed

        declarations.each { create :statement_item, declaration: _1, statement: eligible_statement }
      end

      # Statements::MarkAsPayable.new(eligible_statement).call
      # Statements::MarkAsPaid.new(eligible_statement).call

      travel_to statement.deadline_date do
        declarations.each do |declaration|
          # Finance::ClawbackDeclaration.new(declaration.reload).call
          Declarations::Void.new(declaration: declaration).void
        end
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
          # create(:npq_participant_declaration, :eligible, :voided, course:, cpd_lead_provider:, cohort:)
          d = create(:declaration, :eligible, course:, lead_provider:, cohort:)
          create(:statement_item, declaration: d, statement:)
          Declarations::Void.new(declaration: d).void
        end
      end

      it "is counted" do
        expect(subject.not_eligible_declarations_count).to eql(1)
      end
    end
  end

  describe "#declaration_count_for_milestone" do
    # let(:started_milestone) { Course.schedule_for(course:, cohort:).milestones.find_by(declaration_type: "started") }

    context "when there are no declarations" do
      it do
        # expect(subject.declaration_count_for_milestone(started_milestone)).to be_zero
        expect(subject.declaration_count_for_declaration_type('started')).to be_zero
      end
    end

    context "when there are declarations" do
      before do
        travel_to statement.deadline_date do
          # create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:, cohort:)
          d = create(:declaration, :eligible, course:, lead_provider:, cohort:)
          create(:statement_item, declaration: d, statement:)
        end
      end

      it do
        # expect(subject.declaration_count_for_milestone(started_milestone)).to eql(1)
        expect(subject.declaration_count_for_declaration_type('started')).to eql(1)
      end
    end

    context "when there are multiple declarations from same application and same type" do
      # let(:participant_declaration) { create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:) }
      # before do
      #   travel_to statement.deadline_date do
      #     create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:, cohort:).tap do |pd|
      #       pd.update!(user: participant_declaration.user)
      #     end
      #   end
      # end

      let(:declaration) { create(:declaration, :eligible, course:, lead_provider:) }
      before do
        travel_to statement.deadline_date do
          create(:statement_item, declaration: declaration, statement:)
          create(:declaration, :eligible, course:, lead_provider:, cohort:).tap do |d|
            d.update!(application: declaration.application)
            create(:statement_item, declaration: d, statement:)
          end
        end
      end

      it "is counted once" do
        # expect(subject.declaration_count_for_milestone(started_milestone)).to eql(1)
        expect(subject.declaration_count_for_declaration_type('started')).to eql(1)
      end
    end
  end

  describe "#monthly_service_fees" do
    context "when monthly_service_fee on contract set to nil" do
      # let(:contract) do
      #   create(
      #     :npq_contract,
      #     npq_lead_provider:,
      #     course_identifier: course.identifier,
      #     cohort:,
      #     monthly_service_fee: nil,
      #   )
      # end

      before do
        contract.contract_template.update! monthly_service_fee: nil
      end

      it "returns calculated service fee" do
        expect(subject.monthly_service_fees).to eql(BigDecimal("0.1212631578947368421052631578947368421064e4"))
      end
    end

    context "when monthly_service_fee present on contract" do
      # let(:contract) do
      #   create(
      #     :npq_contract,
      #     :with_monthly_service_fee,
      #     npq_lead_provider:,
      #     course_identifier: course.identifier,
      #   )
      # end

      let(:monthly_service_fee) { 5432.10 }

      before do
        contract.contract_template.update!(monthly_service_fee:)
      end

      it "returns monthly_service_fee from contract" do
        # expect(subject.monthly_service_fees).to eql(5432.10)
        expect(subject.monthly_service_fees).to eql(monthly_service_fee)
      end
    end

    context "when monthly_service_fee on contract set to 0.0" do
      # let(:contract) do
      #   create(
      #     :npq_contract,
      #     npq_lead_provider:,
      #     course_identifier: course.identifier,
      #     monthly_service_fee: 0.0,
      #   )
      # end

      let(:monthly_service_fee) { 0.0 }

      before do
        contract.contract_template.update!(monthly_service_fee:)
      end

      it "returns zero monthly_service_fee from contract" do
        # expect(subject.monthly_service_fees).to eql(0.0)
        expect(subject.monthly_service_fees).to eql(monthly_service_fee)
      end
    end
  end

  describe "#service_fees_per_participant" do
    # it "returns calculated service_fees_per_participant" do
    #   expect(subject.service_fees_per_participant).to eql(BigDecimal("0.16842105263157894736842105263157894737e2"))
    # end

    context "when monthly_service_fee present on contract" do
      let(:monthly_service_fee) { nil }

      before do
        contract.contract_template.update!(monthly_service_fee:, recruitment_target: 438)
      end

      it "returns calculated service_fees_per_participant" do
        expect(subject.service_fees_per_participant).to eql(BigDecimal("0.16842105263157894736842105263157894737e2"))
      end
    end

    context "when monthly_service_fee present on contract" do
      # let(:contract) do
      #   create(
      #     :npq_contract,
      #     :with_monthly_service_fee,
      #     npq_lead_provider:,
      #     course_identifier: course.identifier,
      #     recruitment_target: 438,
      #   )
      # end

      let(:monthly_service_fee) { 5432.10 }

      before do
        contract.contract_template.update!(monthly_service_fee:, recruitment_target: 438)
      end

      it "returns value calulated from monthly_service_fee from contract" do
        expected = BigDecimal("0.12402054794520547945205479452054794521e2")

        expect(subject.service_fees_per_participant).to eql(expected)
      end
    end
  end

  describe "#course_has_targeted_delivery_funding?" do
    # let(:statement) { create(:npq_statement) }

    context "Early headship coaching offer" do
      # let!(:course) { create(:npq_ehco_course) }
      let!(:course) { create(:course, :early_headship_coaching_offer) }

      it do
        expect(subject.course_has_targeted_delivery_funding?).to be false
      end
    end

    context "Additional support offer" do
      # let!(:course) { create(:npq_aso_course) }
      let!(:course) { create(:course, :additional_support_offer) }

      it do
        expect(subject.course_has_targeted_delivery_funding?).to be false
      end
    end

    context "Leadership course" do
      # let!(:course) { create(:npq_leadership_course) }
      let!(:course) { create(:course, :early_years_leadership) }

      it do
        expect(subject.course_has_targeted_delivery_funding?).to be true
      end
    end
  end

  describe "#targeted_delivery_funding_declarations_count" do
    # let(:participant_profile) do
    #   create(
    #     :npq_application,
    #     :accepted,
    #     :eligible_for_funding,
    #     course:,
    #     npq_lead_provider:,
    #     cohort:,
    #     eligible_for_funding: true,
    #     targeted_delivery_funding_eligibility: true,
    #   ).profile
    # end

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
          # create(:npq_participant_declaration, :eligible, course:, cpd_lead_provider:, participant_profile:, cohort:)
          d = create(:declaration, :eligible, course:, lead_provider:, application:, cohort:)
          create(:statement_item, declaration: d, statement:)
        end
      end

      it "is counted" do
        expect(subject.targeted_delivery_funding_declarations_count).to eql(1)
      end
    end

    context "when multiple declarations from same application of one type" do
      # let(:participant_profile) do
      #   create(
      #     :npq_application,
      #     :accepted,
      #     :eligible_for_funding,
      #     :with_started_declaration,
      #     course:,
      #     npq_lead_provider:,
      #     eligible_for_funding: true,
      #     targeted_delivery_funding_eligibility: true,
      #     cohort:,
      #   )
      # end

      # before do
      #   travel_to statement.deadline_date do
      #     create(:npq_participant_declaration, course:, cpd_lead_provider:, participant_profile:, declaration_type: "retained-1", course_identifier: course.identifier, cohort:)
      #   end
      # end

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
        travel_to statement.deadline_date do
          create(:statement_item, declaration: application.declarations.first, statement:)
          d = create(:declaration, course:, lead_provider:, application:, declaration_type: "retained-1", cohort:)
          create(:statement_item, declaration: d, statement:)
        end
      end

      it "has two declarations" do
        # expect(ParticipantDeclaration.count).to eql(2)
        expect(Declaration.count).to eql(2)
        expect(subject.statement.statement_items.count).to eql(2)
      end

      it "has one targeted delivery funding declaration" do
        expect(subject.targeted_delivery_funding_declarations_count).to eql(1)
      end
    end
  end

  describe "#targeted_delivery_funding_refundable_declarations_count" do
    # let(:participant_profile) do
    #   create(
    #     :npq_application,
    #     :accepted,
    #     :eligible_for_funding,
    #     course:,
    #     npq_lead_provider:,
    #     cohort:,
    #     eligible_for_funding: true,
    #     targeted_delivery_funding_eligibility: true,
    #   ).profile
    # end

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
        # travel_to create(:npq_statement, :next_output_fee, deadline_date: statement.deadline_date - 1.month, cpd_lead_provider:).deadline_date do
        #   create(:npq_participant_declaration, :paid, course:, cpd_lead_provider:, participant_profile:, cohort:)
        # end
        travel_to create(:statement, :next_output_fee, lead_provider:).deadline_date do
          d = create(:declaration, :paid, course:, lead_provider:, application:, cohort:)
          create(:statement_item, declaration: d, statement:)
          d
        end
      end

      before do
        travel_to statement.deadline_date do
          # Finance::ClawbackDeclaration.new(to_be_awaiting_clawed_back).call
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
