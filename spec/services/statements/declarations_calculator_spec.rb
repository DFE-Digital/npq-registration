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
  let(:aso_course) { create(:course, :additional_support_offer) }
  let(:ehco_course) { create(:course, :early_headship_coaching_offer) }
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
  let(:other_lead_provider_declaration) { create(:declaration, :eligible, declaration_type: "started", application: application_for_another_lead_provider, course:, lead_provider: other_lead_provider, cohort:, statement:) }

  # milestones
  let(:milestones_for_all_declaration_types) do
    create(:milestone, declaration_type: "retained-1", schedule: specialist_leadership_retained_1_application.schedule)
    create(:milestone, declaration_type: "retained-1", schedule: aso_retained_1_application.schedule)
    retained_1_milestone_leadership
    create(:milestone_statement, milestone: retained_1_milestone_leadership, statement:)
    create(:milestone, declaration_type: "retained-1", schedule: ehco_application_not_penultimate.schedule)
    retained_2_milestone_leadership
    create(:milestone_statement, milestone: retained_2_milestone_leadership, statement:)
    create(:milestone, declaration_type: "retained-2", schedule: ehco_retained_2_application.schedule)
    create(:milestone, declaration_type: "retained-2", schedule: aso_retained_1_application.schedule)
    create(:milestone_statement, milestone: completed_milestone_specialist, statement:)
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

  subject(:declarations_calculator) { described_class.new(statement:) }

  before do
    # applications
    other_cohort_application
    not_accepted_yet_application
    accepted_applications
    application_for_another_lead_provider

    # started declarations
    create(:declaration, declaration_type: "started", application: started_application, course:, lead_provider:, cohort:, statement:)
    create(:declaration, declaration_type: "started", application: withdrawn_started_application, lead_provider:, cohort:, statement:)
    create(:declaration, declaration_type: "started", application: deferred_started_application, lead_provider:, cohort:, statement:)
    create(:declaration, declaration_type: "started", application: application_for_another_lead_provider, lead_provider: other_lead_provider, cohort:, statement:)

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
      other_lead_provider_declaration
    end
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

      before { retained_1_milestone_leadership }

      it "returns the started active applications in the statement's cohort" do
        expect(expected_applications).to contain_exactly(started_application)
      end
    end

    context "when the milestone declaration type is: retained-2" do
      let(:declaration_type) { "retained-2" }

      before { retained_2_milestone_leadership }

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
            declarations_calculator.expected_applications("started") +
            declarations_calculator.expected_applications("retained-1") +
            declarations_calculator.expected_applications("retained-2") +
            declarations_calculator.expected_applications("completed"),
          )
        end
      end

      context "when there is not a started milestone" do
        it "returns the sum of all expected applications" do
          expect(expected_applications).to match_array(
            declarations_calculator.expected_applications("retained-1") +
            declarations_calculator.expected_applications("retained-2") +
            declarations_calculator.expected_applications("completed"),
          )
        end
      end
    end

    context "when the declaration type is invalid" do
      let(:declaration_type) { :started } # using a symbol instead of a string

      it "raises an error" do
        expect { expected_applications }.to raise_error("Invalid declaration type")
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
