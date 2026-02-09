# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::DeclarationsCalculator do
  let(:cohort) { create(:cohort) }
  let(:other_cohort) { create(:cohort) }

  let(:lead_provider) { create :lead_provider }
  let(:other_lead_provider) { create :lead_provider }
  let(:statement) { create(:statement, lead_provider:, cohort:, month: 1, year: 2026) }

  let(:leadership_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }
  let(:specialist_schedule) { create(:schedule, :npq_specialist_autumn, cohort:) }

  # milestones
  let(:started_milestone) { create(:milestone, schedule: started_application.schedule, declaration_type: "started") }
  let(:retained_1_milestone_leadership) { create(:milestone, schedule: leadership_schedule, declaration_type: "retained-1") }
  let(:retained_2_milestone_leadership) { create(:milestone, schedule: leadership_schedule, declaration_type: "retained-2") }
  let(:completed_milestone_specialist) { create(:milestone, schedule: specialist_schedule, declaration_type: "completed") }

  let(:leadership_course) { create(:course, :senior_leadership) }
  let(:specialist_course) { create(:course, :leading_teaching) }
  let(:course) { leadership_course }

  # applications
  let(:not_accepted_yet_application) { create(:application, :eligible_for_funding, course:, lead_provider:, cohort:) }
  let(:other_cohort_application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:, cohort: other_cohort) }
  let(:application_for_another_lead_provider) { create(:application, :accepted, :eligible_for_funding, course:, cohort:, lead_provider: other_lead_provider) }

  # started applications
  let(:started_application) { create(:application, :accepted, course:, lead_provider:, cohort:, schedule: leadership_schedule) }
  let(:withdrawn_started_application) { create(:application, :withdrawn, course:, lead_provider:, cohort:, schedule: leadership_schedule) }
  let(:deferred_started_application) { create(:application, :deferred, course:, lead_provider:, cohort:, schedule: leadership_schedule) }
  let(:application_with_other_declaration_type_declaration) { create(:application, :accepted, course:) }

  # retained-1 applications
  let(:leadership_retained_1_application) { create(:application, :accepted, :eligible_for_funding, course:, lead_provider:, cohort:) }
  let(:specialist_retained_1_application) { create(:application, :accepted, :eligible_for_funding, course: specialist_course, lead_provider:, cohort:) }
  let(:withdrawn_leadership_retained_1_application) { create(:application, :withdrawn, course:, lead_provider:, cohort:) }
  let(:deferred_leadership_retained_1_application) { create(:application, :deferred, course:, lead_provider:, cohort:) }

  # retained-2 applications
  let(:leadership_retained_2_application) { create(:application, :accepted, :eligible_for_funding, course: leadership_course, lead_provider:, cohort:) }

  let(:accepted_applications) do
    [
      started_application,
      leadership_retained_1_application,
      specialist_retained_1_application,
      leadership_retained_2_application,
    ]
  end

  # declarations
  let(:started_declaration) { create(:declaration, :eligible, declaration_type: "started", application: started_application, course:, lead_provider:, cohort:, statement:) }
  let(:other_cohort_declaration) { create(:declaration, :eligible, declaration_type: "started", application: other_cohort_application, course:, lead_provider:, cohort: other_cohort, statement:) }
  let(:retained_1_declaration) { create(:declaration, :eligible, declaration_type: "retained-1", application: application_with_other_declaration_type_declaration, course:, lead_provider:, cohort:, statement:) }
  let(:other_lead_provider_declaration) { create(:declaration, :eligible, declaration_type: "started", application: application_for_another_lead_provider, course:, lead_provider: other_lead_provider, cohort:, statement:) }

  # milestones
  let(:milestones_for_all_declaration_types) do
    create(:milestone, declaration_type: "retained-1", schedule: specialist_retained_1_application.schedule)
    retained_1_milestone_leadership
    create(:milestone_statement, milestone: retained_1_milestone_leadership, statement:)
    retained_2_milestone_leadership
    create(:milestone_statement, milestone: retained_2_milestone_leadership, statement:)
    create(:milestone_statement, milestone: completed_milestone_specialist, statement:)
    create(:milestone, declaration_type: "completed", schedule: leadership_retained_2_application.schedule)
  end

  let(:milestones_for_completed_declaration_type) do
    create(:milestone, declaration_type: "retained-1", schedule: specialist_retained_1_application.schedule)
    create(:milestone, declaration_type: "retained-1", schedule: leadership_retained_1_application.schedule)
    create(:milestone, declaration_type: "retained-2", schedule: leadership_retained_2_application.schedule)
    create(:milestone, declaration_type: "completed", schedule: specialist_retained_1_application.schedule)
    create(:milestone, declaration_type: "completed", schedule: leadership_retained_2_application.schedule)
  end

  subject(:declarations_calculator) { described_class.new(statement:) }

  before do
    other_cohort_application
    not_accepted_yet_application
    accepted_applications
    application_for_another_lead_provider
  end

  describe "#expected_applications" do
    subject(:expected_applications) { declarations_calculator.expected_applications(declaration_type) }

    context "when the milestone declaration type is: started" do
      let(:declaration_type) { "started" }

      context "when the statement has a started milestone" do
        before do
          create(:milestone_statement, milestone: started_milestone, statement:)
        end

        it "returns the accepted applications for the statement's cohort" do
          expect(expected_applications).to match_array(Application.accepted.where(cohort: statement.cohort, lead_provider:).all)
        end
      end

      context "when the statement does not have a started milestone" do
        it "returns zero" do
          expect(expected_applications).to be_empty
        end
      end
    end

    context "when the milestone declaration type is: retained-1" do
      let(:declaration_type) { "retained-1" }

      before do
        retained_1_milestone_leadership
        create(:declaration, declaration_type: "started", application: started_application, course:, lead_provider:, cohort:, statement:)
        create(:declaration, declaration_type: "started", application: withdrawn_started_application, lead_provider:, cohort:, statement:)
        create(:declaration, declaration_type: "started", application: deferred_started_application, lead_provider:, cohort:, statement:)
        create(:declaration, declaration_type: "started", application: application_for_another_lead_provider, lead_provider: other_lead_provider, cohort:, statement:)
      end

      it "returns the started active applications in the statement's cohort" do
        expect(expected_applications).to contain_exactly(started_application)
      end
    end

    context "when the milestone declaration type is: retained-2" do
      let(:declaration_type) { "retained-2" }

      before do
        retained_2_milestone_leadership
        create(:declaration, declaration_type: "retained-1", application: leadership_retained_1_application, course:, lead_provider:, cohort:, statement:)
        create(:declaration, declaration_type: "retained-1", application: withdrawn_leadership_retained_1_application, lead_provider:, cohort:, statement:)
        create(:declaration, declaration_type: "retained-1", application: deferred_leadership_retained_1_application, lead_provider:, cohort:, statement:)
      end

      it "returns the retained-1 active applications in the statement's cohort" do
        expect(expected_applications).to contain_exactly(leadership_retained_1_application)
      end
    end

    context "when the milestone declaration type is: completed" do
      let(:declaration_type) { "completed" }

      context "when there is an application with a schedule that has a retained-2 milestone" do
        let(:completed_leadership_application) do
          leadership_retained_2_application.tap do |application|
            create(:milestone, declaration_type: "retained-2", schedule: application.schedule)
            create(:milestone, declaration_type: "completed", schedule: application.schedule)
          end
        end

        context "and a retained-2 declaration" do
          before { create(:declaration, declaration_type: "retained-2", application: completed_leadership_application, lead_provider:, cohort:, statement:) }

          it "the application is included in the expected applications" do
            expect(expected_applications).to contain_exactly(completed_leadership_application)
          end
        end

        context "and a retained-1 declaration" do
          before { create(:declaration, declaration_type: "retained-1", application: completed_leadership_application, lead_provider:, cohort:, statement:) }

          it "the application is not included in the expected applications" do
            expect(expected_applications).to be_empty
          end
        end
      end

      context "when there is an application with a schedule that does not have a retained-2 milestone and a retained-1 declaration" do
        let(:completed_specialist_application) do
          specialist_retained_1_application.tap do |application|
            create(:milestone, declaration_type: "retained-1", schedule: application.schedule)
            create(:milestone, declaration_type: "completed", schedule: application.schedule)
          end
        end

        before { create(:declaration, declaration_type: "retained-1", application: completed_specialist_application, lead_provider:, cohort:, statement:) }

        it "the application is included in the expected applications" do
          expect(expected_applications).to contain_exactly(completed_specialist_application)
        end
      end
    end

    context "when the declaration type is nil" do
      let(:declaration_type) { nil }

      before { milestones_for_all_declaration_types }

      it "raises an error" do
        expect { expected_applications }.to raise_error(Statements::DeclarationsCalculator::InvalidDeclarationType, "Invalid declaration type: , class: NilClass")
      end
    end

    context "when the declaration type is invalid" do
      let(:declaration_type) { :started } # using a symbol instead of a string

      it "raises an error" do
        expect { expected_applications }.to raise_error(Statements::DeclarationsCalculator::InvalidDeclarationType, "Invalid declaration type: started, class: Symbol")
      end
    end
  end

  describe "#total_expected_applications" do
    subject(:total_expected_applications) { declarations_calculator.total_expected_applications }

    before do
      milestones_for_all_declaration_types
      create(:declaration, declaration_type: "started", application: started_application, course:, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-1", application: leadership_retained_1_application, course:, lead_provider:, cohort:, statement:)
      create(:declaration, declaration_type: "retained-2", application: leadership_retained_2_application, lead_provider:, cohort:, statement:)
    end

    context "when there is a started milestone" do
      before { create(:milestone_statement, milestone: started_milestone, statement:) }

      it "returns the sum of all expected applications" do
        expect(total_expected_applications).to eq 7 # 4 started, and one each of the other three types
      end
    end

    context "when there is not a started milestone" do
      it "returns the sum of all expected applications" do
        expect(total_expected_applications).to eq 3
      end
    end
  end

  describe "#received_declarations" do
    let(:other_declaration_type_declaration) { create(:declaration, :eligible, declaration_type: "retained-1", application: application_with_other_declaration_type_declaration, course:, lead_provider:, cohort:, statement:) }
    let(:declaration_without_milestone) { create(:declaration, :eligible, declaration_type: "retained-2", application: leadership_retained_2_application, course:, lead_provider:, cohort:, statement:) }

    before do
      started_declaration
      declaration_without_milestone
      retained_1_declaration
      create(:milestone_statement, milestone: started_milestone, statement:)
      retained_1_milestone = create(:milestone, declaration_type: "retained-1", schedule: application_with_other_declaration_type_declaration.schedule)
      create(:milestone_statement, milestone: retained_1_milestone, statement:)
    end

    it "returns the billable declarations for the statement of the given declaration type, in the given cohort" do
      expect(declarations_calculator.received_declarations("started")).to contain_exactly(started_declaration)
    end

    context "when the declaration type is nil" do
      it "returns all billable declarations for the statement, in the given cohort" do
        expect(declarations_calculator.received_declarations).to contain_exactly(started_declaration, declaration_without_milestone, retained_1_declaration)
      end
    end
  end

  describe "#remaining_declarations_count" do
    subject { declarations_calculator.remaining_declarations_count(declaration_type) }

    let(:accepted_applications) { create_list(:application, 4, :accepted, course:, lead_provider:, cohort:) }

    before { accepted_applications }

    context "when the milestone declaration type is: started" do
      let(:declaration_type) { "started" }

      before { started_declaration }

      context "when there is a started milestone, and hence an expected application" do
        before { create(:milestone_statement, milestone: started_milestone, statement:) }

        it "returns the expected applications minus received declarations count" do
          expected_applications_count = 5
          received_declarations_count = 1
          expect(subject).to eq expected_applications_count - received_declarations_count
        end
      end

      context "when there is no started milestone, and hence no expected applications" do
        it "returns zero" do
          expect(subject).to eq 0
        end
      end
    end

    def create_applications_with_declaration_and_milestone(declaration_type:, milestone_declaration_type:)
      application = create(:application, :accepted, course:, lead_provider:, cohort:, schedule: leadership_schedule)
      milestone = create(:milestone, declaration_type: milestone_declaration_type, schedule: application.schedule)
      create(:milestone_statement, milestone: milestone, statement:)
      create(:declaration, :eligible, declaration_type:, application:, course:, lead_provider:, cohort:, statement:)
      second_application = create(:application, :accepted, course:, lead_provider:, cohort:, schedule: leadership_schedule)
      create(:declaration, :eligible, declaration_type:, application: second_application, course:, lead_provider:, cohort:, statement:)
    end

    context "when the milestone declaration type is: retained-1" do
      let(:declaration_type) { "retained-1" }

      before do
        create_applications_with_declaration_and_milestone(declaration_type: "started", milestone_declaration_type: "retained-1")
        create(:declaration, :eligible, declaration_type:, course:, lead_provider:, cohort:, statement:)
        create(:milestone_statement, milestone: started_milestone, statement:)
      end

      it "returns the expected applications minus received declarations count plus the remaining started declarations count" do
        expected_applications_count = 2
        received_declarations_count = 1
        remaining_started_declarations_count = 5
        expect(subject).to eq(expected_applications_count - received_declarations_count + remaining_started_declarations_count)
      end
    end

    context "when the milestone declaration type is: retained-2" do
      let(:declaration_type) { "retained-2" }

      before do
        create(:milestone_statement, milestone: started_milestone, statement:)
        create_applications_with_declaration_and_milestone(declaration_type: "started", milestone_declaration_type: "retained-1")
        create_applications_with_declaration_and_milestone(declaration_type: "retained-1", milestone_declaration_type: "retained-2")
        create(:declaration, :eligible, declaration_type:, course:, lead_provider:, cohort:, statement:)
        create(:declaration, :eligible, declaration_type: "retained-1", course:, lead_provider:, cohort:, statement:)
      end

      it "returns the expected applications minus received declarations count plus the remaining started and retained-1 declarations count" do
        expected_applications_count = 2
        received_declarations_count = 1
        remaining_started_and_retained_1_declarations_count = 6

        expect(subject).to eq(expected_applications_count - received_declarations_count + remaining_started_and_retained_1_declarations_count)
      end
    end

    context "when the milestone declaration type is: completed" do
      let(:declaration_type) { "completed" }

      before do
        create(:milestone_statement, milestone: started_milestone, statement:)
        create_applications_with_declaration_and_milestone(declaration_type: "started", milestone_declaration_type: "retained-1")
        create_applications_with_declaration_and_milestone(declaration_type: "retained-1", milestone_declaration_type: "retained-2")
        create(:declaration, :eligible, declaration_type:, course:, lead_provider:, cohort:, statement:)
        create(:declaration, :eligible, declaration_type: "retained-1", course:, lead_provider:, cohort:, statement:)
        create(:declaration, :eligible, declaration_type: "retained-2", course:, lead_provider:, cohort:, statement:)
      end

      context "when there is an application with a schedule that has a retained-2 milestone" do
        before do
          create_applications_with_declaration_and_milestone(declaration_type: "retained-2", milestone_declaration_type: "completed")
        end

        it "returns the expected applications minus received declarations count plus the remaining started, retained-1 and retained-2 declarations count" do
          expected_applications_count = 2
          received_declarations_count = 1
          remaining_started_retained_1_and_retained_2_declarations_count = 7
          expect(subject).to eq(expected_applications_count - received_declarations_count + remaining_started_retained_1_and_retained_2_declarations_count)
        end
      end

      context "when there is an application with a schedule that does not have a retained-2 milestone" do
        before do
          application = create(:application, :accepted, course: specialist_course, lead_provider:, cohort:, schedule: specialist_schedule)
          milestone = create(:milestone, declaration_type: "completed", schedule: application.schedule)
          create(:milestone_statement, milestone: milestone, statement:)
          create(:declaration, :eligible, declaration_type: "retained-1", application:, course:, lead_provider:, cohort:, statement:)
          second_application = create(:application, :accepted, course: specialist_course, lead_provider:, cohort:, schedule: specialist_schedule)
          create(:declaration, :eligible, declaration_type: "retained-1", application: second_application, course:, lead_provider:, cohort:, statement:)
        end

        it "returns the expected applications minus received declarations count plus the remaining started, retained-1 and retained-2 declarations count" do
          expected_applications_count = 2
          received_declarations_count = 1
          remaining_started_retained_1_and_retained_2_declarations_count = 7
          expect(subject).to eq(expected_applications_count - received_declarations_count + remaining_started_retained_1_and_retained_2_declarations_count)
        end
      end
    end
  end

  describe "#total_remaining_declarations_count" do
    subject { declarations_calculator.total_remaining_declarations_count }

    before do
      create(:milestone_statement, milestone: started_milestone, statement:)
      create(:milestone_statement, milestone: retained_2_milestone_leadership, statement:)
      create(:milestone, schedule: specialist_schedule, declaration_type: "completed")
    end

    context "when there have been no received declarations" do
      it "returns the total expected applications" do
        expect(subject).to eq(4)
      end
    end

    context "when there have been some received declarations" do
      before do
        started_declaration
        retained_1_declaration
        create(:declaration, :eligible, declaration_type: "retained-2", lead_provider:, cohort:, statement:)
        create(:declaration, :eligible, declaration_type: "completed", lead_provider:, cohort:, statement:)
      end

      it "returns the total expected applications minus the number of declarations received for milestones on this statement" do
        expect(Declaration.count).to eq 4
        total_expected_applications = 4
        declarations_received_for_milestones_on_statement = 2 # i.e. declarations for "started" and "retained-2" milestones only
        expect(subject).to eq(total_expected_applications - declarations_received_for_milestones_on_statement)
      end
    end
  end
end
