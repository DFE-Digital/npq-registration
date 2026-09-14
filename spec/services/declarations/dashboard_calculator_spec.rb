# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::DashboardCalculator do
  let(:cohort) { create(:cohort, :current) }
  let(:other_cohort) { create(:cohort, :previous) }

  let(:lead_provider) { create(:lead_provider) }
  let(:other_lead_provider) { create(:lead_provider) }

  let(:leadership_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }
  let(:specialist_schedule) { create(:schedule, :npq_specialist_autumn, cohort:) }

  let(:past_statement) { create(:statement, lead_provider:, cohort:, for_date: 2.months.ago) }
  let(:another_past_statement) { create(:statement, lead_provider:, cohort:, for_date: 1.month.ago) }
  let(:future_statement) { create(:statement, lead_provider:, cohort:, for_date: 2.months.from_now) }

  subject(:calculator) { described_class.new(lead_provider:, cohort:) }

  def add_milestone(statement, schedule, declaration_type)
    milestone = create(:milestone, schedule:, declaration_type:)
    create(:milestone_statement, milestone:, statement:)
    milestone
  end

  def create_application(*traits, schedule: leadership_schedule, lead_provider: self.lead_provider, cohort: self.cohort)
    create(:application, *traits, lead_provider:, cohort:, schedule:)
  end

  describe "#milestone_declaration_types" do
    it "takes the milestones of the past statements" do
      add_milestone(past_statement, leadership_schedule, "started")
      add_milestone(another_past_statement, leadership_schedule, "retained-1")

      expect(calculator.milestone_declaration_types).to contain_exactly("started", "retained-1")
    end

    it "ignores the milestones of statements that are not past yet" do
      add_milestone(future_statement, leadership_schedule, "started")

      expect(calculator.milestone_declaration_types).to be_empty
    end

    it "ignores the milestones of statements without an output fee" do
      statement = create(:statement, lead_provider:, cohort:, for_date: 2.months.ago, output_fee: true)
      add_milestone(statement, leadership_schedule, "started")
      statement.milestone_statements.destroy_all
      statement.update!(output_fee: false)

      expect(calculator.milestone_declaration_types).to be_empty
    end

    it "ignores the milestones of another lead provider or another cohort" do
      add_milestone(create(:statement, lead_provider: other_lead_provider, cohort:, for_date: 2.months.ago), leadership_schedule, "started")
      add_milestone(create(:statement, lead_provider:, cohort: other_cohort, for_date: 2.months.ago), leadership_schedule, "retained-1")

      expect(calculator.milestone_declaration_types).to be_empty
    end
  end

  describe "#expected_applications_count" do
    context "when the started milestone is on a past statement" do
      before { add_milestone(past_statement, leadership_schedule, "started") }

      it "counts the accepted applications of the lead provider and cohort" do
        create_application(:accepted)
        create_application(:accepted)
        create_application(:pending)
        create_application(:accepted, lead_provider: other_lead_provider)
        create(:application, :accepted, lead_provider:, cohort: other_cohort)

        expect(calculator.expected_applications_count("started")).to eq(2)
      end
    end

    context "when the started milestone is not on a past statement yet" do
      before { add_milestone(future_statement, leadership_schedule, "started") }

      it "is zero" do
        create_application(:accepted)

        expect(calculator.expected_applications_count("started")).to be_zero
      end
    end

    context "when the retained-1 milestone is on a past statement" do
      before do
        add_milestone(past_statement, leadership_schedule, "started")
        add_milestone(another_past_statement, leadership_schedule, "retained-1")
      end

      it "counts the applications with a started declaration, without the withdrawn and deferred ones" do
        started_application = create_application(:accepted)
        withdrawn_application = create_application(:withdrawn)
        deferred_application = create_application(:deferred)

        [started_application, withdrawn_application, deferred_application].each do |application|
          create(:declaration, :eligible, declaration_type: "started", application:, lead_provider:, cohort:, statement: past_statement)
        end

        create_application(:accepted)

        expect(calculator.expected_applications_count("retained-1")).to eq(1)
      end
    end

    it "raises for an unknown declaration type" do
      expect { calculator.expected_applications_count("unknown") }.to raise_error(described_class::InvalidDeclarationType)
    end
  end

  describe "#received_declarations_count" do
    before { add_milestone(past_statement, leadership_schedule, "started") }

    it "counts the billable declarations of the lead provider and cohort, whatever statement they are on" do
      create(:declaration, :eligible, declaration_type: "started", application: create_application(:accepted), lead_provider:, cohort:, statement: past_statement)
      create(:declaration, :paid, declaration_type: "started", application: create_application(:accepted), lead_provider:, cohort:, statement: another_past_statement)
      create(:declaration, :voided, declaration_type: "started", application: create_application(:accepted), lead_provider:, cohort:)
      create(:declaration, :eligible, declaration_type: "started", application: create_application(:accepted, lead_provider: other_lead_provider), lead_provider: other_lead_provider, cohort:)

      expect(calculator.received_declarations_count("started")).to eq(2)
    end

    it "counts every declaration type when no type is given" do
      create(:declaration, :eligible, declaration_type: "started", application: create_application(:accepted), lead_provider:, cohort:)
      create(:declaration, :eligible, declaration_type: "retained-1", application: create_application(:accepted), lead_provider:, cohort:)

      expect(calculator.received_declarations_count).to eq(2)
    end
  end

  describe "#remaining_declarations_count" do
    before { add_milestone(past_statement, leadership_schedule, "started") }

    it "is the expected applications minus the received declarations" do
      3.times { create_application(:accepted) }
      create(:declaration, :eligible, declaration_type: "started", application: create_application(:accepted), lead_provider:, cohort:)

      expect(calculator.remaining_declarations_count("started")).to eq(3)
    end

    it "is zero when nothing is expected" do
      expect(calculator.remaining_declarations_count("completed")).to be_zero
    end

    it "adds the declarations still missing from the previous milestones" do
      add_milestone(another_past_statement, leadership_schedule, "retained-1")

      started_application = create_application(:accepted)
      create(:declaration, :eligible, declaration_type: "started", application: started_application, lead_provider:, cohort:)
      create_application(:accepted)

      # started: 2 expected, 1 received, so 1 is still missing
      # retained-1: 1 expected, 0 received, plus the 1 missing from started
      expect(calculator.remaining_declarations_count("retained-1")).to eq(2)
    end
  end

  describe "totals" do
    before do
      add_milestone(past_statement, leadership_schedule, "started")
      add_milestone(another_past_statement, leadership_schedule, "retained-1")
    end

    it "adds up the expected applications of the reached milestones" do
      started_application = create_application(:accepted)
      create(:declaration, :eligible, declaration_type: "started", application: started_application, lead_provider:, cohort:)
      create_application(:accepted)

      # started: 2 accepted applications, retained-1: 1 application with a started declaration
      expect(calculator.total_expected_applications).to eq(3)
    end

    it "takes the received declarations off the expected ones" do
      started_application = create_application(:accepted)
      create(:declaration, :eligible, declaration_type: "started", application: started_application, lead_provider:, cohort:)
      create_application(:accepted)

      expect(calculator.total_remaining_declarations_count).to eq(2)
    end
  end
end
