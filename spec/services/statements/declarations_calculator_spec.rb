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
  let(:application_with_eligible_declaration) { create(:application, :accepted, course:) }
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
  let(:eligible_declaration) { create(:declaration, :eligible, declaration_type: "started", application: application_with_eligible_declaration, course:, lead_provider:, cohort:, statement:) }
  let(:other_cohort_declaration) { create(:declaration, :eligible, declaration_type: "started", application: other_cohort_application, course:, lead_provider:, cohort: other_cohort, statement:) }
  let(:other_declaration_type_declaration) { create(:declaration, :eligible, declaration_type: "retained-1", application: application_with_other_declaration_type_declaration, course:, lead_provider:, cohort:, statement:) }
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
    # applications
    other_cohort_application
    not_accepted_yet_application
    accepted_applications
    application_for_another_lead_provider
  end

  describe "#expected_applications" do
    subject(:expected_applications) { declarations_calculator.expected_applications(declaration_type) }

    context "when the milestone declaration type is: started" do
      let(:declaration_type) { "started" }

      it "returns the accepted applications for the statement's cohort" do
        expect(expected_applications).to match_array(Application.accepted.where(cohort: statement.cohort, lead_provider:).all)
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

  describe "#all_expected_applications" do
    subject(:all_expected_applications) { declarations_calculator.all_expected_applications }

    before { milestones_for_all_declaration_types }

    context "when there is a started milestone" do
      before do
        started_milestone = create(:milestone, declaration_type: "started", schedule: started_application.schedule)
        create(:milestone_statement, milestone: started_milestone, statement:)
      end

      it "returns the sum of all expected applications" do
        expect(all_expected_applications).to match_array(
          declarations_calculator.expected_applications("started") +
          declarations_calculator.expected_applications("retained-1") +
          declarations_calculator.expected_applications("retained-2") +
          declarations_calculator.expected_applications("completed"),
        )
      end
    end

    context "when there is not a started milestone" do
      it "returns the sum of all expected applications" do
        expect(all_expected_applications).to match_array(
          declarations_calculator.expected_applications("retained-1") +
          declarations_calculator.expected_applications("retained-2") +
          declarations_calculator.expected_applications("completed"),
        )
      end
    end
  end

  describe "#received_declarations" do
    let(:other_declaration_type_declaration) { create(:declaration, :eligible, declaration_type: "retained-1", application: application_with_other_declaration_type_declaration, course:, lead_provider:, cohort:, statement:) }
    let(:declaration_without_milestone) { create(:declaration, :eligible, declaration_type: "retained-2", application: leadership_retained_2_application, course:, lead_provider:, cohort:, statement:) }

    before do
      declaration_without_milestone
      started_milestone = create(:milestone, declaration_type: "started", schedule: application_with_eligible_declaration.schedule)
      create(:milestone_statement, milestone: started_milestone, statement:)
      retained_1_milestone = create(:milestone, declaration_type: "retained-1", schedule: application_with_other_declaration_type_declaration.schedule)
      create(:milestone_statement, milestone: retained_1_milestone, statement:)
    end

    it "returns the billable declarations for the statement of the given declaration type, in the given cohort" do
      expect(declarations_calculator.received_declarations("started")).to contain_exactly(eligible_declaration)
    end

    context "when the declaration type is nil" do
      it "returns all billable declarations for the statement of the milestone declaration types, in the given cohort" do
        expect(declarations_calculator.received_declarations).to contain_exactly(eligible_declaration, other_declaration_type_declaration)
      end
    end
  end
end
