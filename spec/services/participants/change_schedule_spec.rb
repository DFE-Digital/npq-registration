# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::ChangeSchedule, type: :model do
  let(:cohort) { create(:cohort, :current) }
  let(:params) do
    {
      lead_provider:,
      participant_id:,
      course_identifier:,
      schedule_identifier: new_schedule_identifier,
      cohort: nil,
    }
  end
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, :senior_leadership) }
  let(:course_identifier) { course.identifier }
  let(:schedule) { create(:schedule, :npq_leadership_spring, cohort:) }
  let(:application_trait) { :accepted }
  let!(:application) { create(:application, application_trait, cohort:, lead_provider:, course:, schedule:) }
  let(:participant) { application.user }
  let(:participant_id) { participant.ecf_id }
  let(:new_cohort) { create(:cohort, :next) }
  let(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort: new_cohort) }
  let(:new_schedule_identifier) { new_schedule.identifier }
  let(:statement) { create(:statement, cohort:, lead_provider:) }
  let!(:contract) { create(:contract, statement:, course:) }

  before do
    new_statement = create(:statement, cohort: new_cohort, lead_provider:)
    create(:contract, statement: new_statement, course:)
  end

  subject(:instance) { described_class.new(params) }

  describe "validations" do
    context "when validating a participant for a change schedule" do
      it_behaves_like "a participant action" do
        let(:params) do
          {
            lead_provider:,
            participant_id:,
            course_identifier:,
            schedule_identifier: new_schedule_identifier,
            cohort: new_cohort.start_year,
          }
        end

        let(:application) { create(:application, :accepted, cohort:, course:, schedule:) }
      end

      it { is_expected.to validate_presence_of(:schedule_identifier).with_message(:blank).with_message("The property '#/schedule_identifier' must be present") }

      context "when the schedule is invalid" do
        let(:new_schedule_identifier) { "invalid" }

        it { is_expected.to have_error_count(1) }
        it { is_expected.to have_error(:schedule_identifier, :blank, "The property '#/schedule_identifier' must be present") }
      end

      context "when the schedule identifier change of the same type again" do
        let(:new_schedule) { create(:schedule, :npq_leadership_spring, cohort:) }

        it { is_expected.to have_error_count(1) }
        it { is_expected.to have_error(:schedule_identifier, :schedule_has_not_changed, "The participant already has the specified schedule") }
      end
    end

    context "when validating an application is not already withdrawn for a change schedule" do
      let(:application_trait) { :withdrawn }
      let(:cohort) { new_cohort }

      it { is_expected.to have_error_count(1) }
      it { is_expected.to have_error(:participant_id, :already_withdrawn, "The participant is already withdrawn") }
    end

    context "when the cohort is changing" do
      let(:params) do
        {
          lead_provider:,
          participant_id:,
          course_identifier:,
          schedule_identifier: new_schedule_identifier,
          cohort: new_cohort.start_year,
        }
      end

      it "allows a change of schedule with cohort" do
        expect(subject.change_schedule).to be_truthy
        application.reload
        expect(application.schedule).to eql(new_schedule)
        expect(application.cohort).to eql(new_cohort)
      end

      context "when reversing a change of schedule/cohort" do
        it "allows a change of schedule to be reversed" do
          expect(subject.change_schedule).to be_truthy
          application.reload
          expect(application.schedule).to eql(new_schedule)
          expect(application.cohort).to eql(new_cohort)

          second_change_of_schedule = described_class.new(params.merge({
            schedule_identifier: schedule.identifier,
            cohort: cohort.start_year,
          }))
          expect(second_change_of_schedule.change_schedule).to be_truthy
          application.reload
          expect(application.schedule).to eql(schedule)
          expect(application.cohort).to eql(cohort)
        end

        it "does not allow a change of schedule to be reversed if there are billable or changeable declarations in the new cohort" do
          expect(subject.change_schedule).to be_truthy
          application.reload
          expect(application.schedule).to eql(new_schedule)
          expect(application.cohort).to eql(new_cohort)

          travel_to(Date.new(new_cohort.start_year).end_of_year) do
            create(
              :declaration,
              application:,
              declaration_type: "retained-1",
              state: :payable,
              lead_provider:,
              cohort: new_cohort,
            )
          end
          second_change_of_schedule = described_class.new(params.merge({
            schedule_identifier: schedule.identifier,
            cohort: cohort.start_year,
          }))

          expect(second_change_of_schedule).to have_error(:cohort, :cannot_change_with_declarations, "You cannot change the '#/cohort' field when there are submitted, eligible, payable, or paid declarations in the new cohort")
          expect(second_change_of_schedule.errors.count).to eq 1
        end
      end

      %i[submitted eligible payable paid].each do |state|
        context "when there are #{state} declarations" do
          before do
            create(
              :declaration,
              application:,
              declaration_type: "retained-1",
              state:,
              lead_provider:,
              cohort:,
            )
          end

          context "when changing to another cohort" do
            it { is_expected.to have_error_count(1) }
            it { is_expected.to have_error(:cohort, :cannot_change_with_declarations, "You cannot change the '#/cohort' field when there are submitted, eligible, payable, or paid declarations in the new cohort") }
          end
        end
      end

      context "when moving from funding cohort to funding cohort" do
        let(:cohort) { create(:cohort, :current, :with_funding_cap) }
        let(:new_cohort) { create(:cohort, :next, :with_funding_cap) }

        before do
          application.update!(funded_place: false, eligible_for_funding: true)
        end

        it "does not change funding place if original contract has a funded place" do
          expect(subject.change_schedule).to be_truthy
          application.reload
          expect(application.funded_place).to be_falsey
        end
      end

      context "when moving from non funding cohort to funding cohort" do
        let(:cohort) { create(:cohort, :current, :without_funding_cap) }
        let(:new_cohort) { create(:cohort, :next, :with_funding_cap) }
        let!(:application) do
          create(
            :application,
            :accepted,
            cohort:,
            lead_provider:,
            course:,
            schedule:,
            eligible_for_funding:,
            funded_place: nil,
          )
        end

        context "when `eligible_for_funding` is true" do
          let(:eligible_for_funding) { true }

          it "sets funding place to `true`" do
            expect(subject.change_schedule).to be_truthy
            application.reload
            expect(application.funded_place).to be_truthy
          end
        end

        context "when `eligible_for_funding` is false" do
          let(:eligible_for_funding) { false }

          it "sets funding place to `false`" do
            expect(subject.change_schedule).to be_truthy
            application.reload
            expect(application.funded_place).to be_falsey
          end
        end
      end

      context "when moving from funding cohort to non funding cohort" do
        let(:cohort) { create(:cohort, :current, :with_funding_cap) }
        let(:new_cohort) { create(:cohort, :next, :without_funding_cap) }

        it "does not change the application to the new cohort" do
          expect(subject.change_schedule).to be_falsey

          expect(subject).to have_error(:cohort, :cannot_change_to_cohort_without_funding_cap, "You cannot change the '#/cohort' field from one with a funding cap to one without a funding cap")
          expect(subject.errors.count).to eq(1)
        end
      end

      context "when existing declarations is not valid for new_schedule" do
        before do
          schedule.update!(applies_from: declaration_date.prev_week)
          create(
            :declaration,
            application:,
            declaration_type: "retained-1",
            state: :payable,
            lead_provider:,
            cohort: new_cohort,
            declaration_date:,
          )
        end

        context "when new_schedule does not allow existing declaration_type" do
          let(:declaration_date) { Date.current }

          before do
            new_schedule.update!(allowed_declaration_types: [])
          end

          it "does not allow a change of schedule" do
            expect(subject.change_schedule).to be_falsey
            expect(subject).to have_error(:schedule_identifier, :invalidates_declaration, "Changing schedule would invalidate existing declarations. Please void them first.")
            expect(subject).to have_error_count(1)
          end
        end

        context "when declaration_date is before new_schedule.applies_from" do
          let(:declaration_date) { new_schedule.applies_from - 1.year }

          it "does not allow a change of schedule" do
            expect(subject.change_schedule).to be_falsey
            expect(subject).to have_error(:schedule_identifier, :invalidates_declaration, "Changing schedule would invalidate existing declarations. Please void them first.")
            expect(subject).to have_error_count(1)
          end
        end
      end

      context "when new_schedule is not permitted for course" do
        let(:not_permitted_course_group) { create(:course_group) }

        before do
          new_schedule.update!(course_group: not_permitted_course_group)
        end

        it "does not allow a change of schedule" do
          expect(subject.change_schedule).to be_falsey
          expect(subject).to have_error(:schedule_identifier, :invalid_for_course, "The selected schedule is not valid for the course")
        end
      end
    end

    context "when lead provider has no contract for the cohort and course" do
      let(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }

      before { contract.update!(course: create(:course, :leading_literacy)) }

      it { is_expected.to have_error(:cohort, :missing_contract_for_cohort_and_course, "You cannot change a participant to this cohort as you do not have a contract for the cohort and course. Contact the DfE for assistance.") }
    end
  end

  describe "#change_schedule" do
    context "when changing the schedule only" do
      let!(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }

      it "allows change of schedule" do
        expect(subject.change_schedule).to be_truthy
        application.reload
        expect(application.schedule).to eql(new_schedule)
        expect(application.cohort).to eql(cohort)
      end

      context "when using fallback_cohort" do
        let(:cohort) { create(:cohort, start_year: (Date.current.year + 1)) }

        context "when application has schedule" do
          before do
            create(:schedule, :npq_leadership_autumn, cohort: new_cohort)
            application.schedule.update!(cohort: new_cohort)
          end

          it "fallback to application.schedule.cohort" do
            expect(subject.change_schedule).to be_truthy
            application.reload
            expect(application.cohort).to eql(new_cohort)
          end
        end

        context "when schedule is nil" do
          let(:new_cohort) { create(:cohort, :current) }
          let(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort: new_cohort) }

          before do
            application.update!(schedule: nil)
          end

          it "fallback to Cohort.current" do
            expect(subject.change_schedule).to be_truthy
            application.reload
            expect(application.cohort).to eql(new_cohort)
          end
        end
      end
    end

    context "when the cohort is changing" do
      let(:params) do
        {
          lead_provider:,
          participant_id:,
          course_identifier:,
          schedule_identifier: new_schedule_identifier,
          cohort: new_cohort.start_year,
        }
      end

      it "allows change of schedule with cohort" do
        expect(subject.change_schedule).to be_truthy
        application.reload
        expect(application.schedule).to eql(new_schedule)
        expect(application.cohort).to eql(new_cohort)
      end
    end

    context "when multiple cohorts in same year" do
      let :suffixed_cohort do
        create(:cohort, start_year: cohort.start_year, suffix: "b").tap do |cohort|
          create(:contract, statement: create(:statement, cohort:, lead_provider:),
                            course:)
        end
      end

      let :suffixed_schedule do
        # ensure we have an equivalent schedule which this one should shadow
        new_schedule

        create :schedule, :npq_leadership_autumn, cohort: suffixed_cohort
      end

      let :declaration do
        create(:declaration, :payable, application:, lead_provider:)
      end

      context "with cohort year specified" do
        let :params do
          {
            lead_provider:,
            participant_id:,
            course_identifier:,
            schedule_identifier: suffixed_schedule.identifier,
            cohort: suffixed_cohort.start_year,
          }
        end

        it "allows change of schedule with cohort" do
          expect(subject.change_schedule).to be_truthy
          application.reload
          expect(application.schedule).to eql(suffixed_schedule)
          expect(application.cohort).to eql(suffixed_cohort)
        end

        context "with declarations" do
          before { declaration }

          it "prevents change of schedule" do
            expect(subject.change_schedule).to be_falsey
            expect(subject).to have_error_count(1)
            expect(subject).to have_error(
              :cohort,
              :cannot_change_with_declarations,
              "You cannot change the '#/cohort' field when there are submitted, eligible, payable, or paid declarations in the new cohort",
            )

            application.reload
            expect(application.schedule).to eql(schedule)
            expect(application.cohort).to eql(cohort)
          end
        end

        context "with suffixed cohorts feature turned off" do
          before { allow(Feature).to receive(:suffixed_cohorts?).and_return(false) }

          let(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort: cohort) }

          it "chooses schedule from cohort with suffix of a" do
            expect(subject.change_schedule).to be_truthy

            application.reload
            expect(application.schedule).to eql(new_schedule)
            expect(application.cohort).to eql(cohort)
          end
        end
      end

      context "without cohort year specified" do
        let :params do
          {
            lead_provider:,
            participant_id:,
            course_identifier:,
            schedule_identifier: suffixed_schedule.identifier,
          }
        end

        it "allows change of schedule with cohort" do
          expect(subject.change_schedule).to be_truthy
          application.reload
          expect(application.schedule).to eql(suffixed_schedule)
          expect(application.cohort).to eql(suffixed_cohort)
        end

        context "with declarations" do
          before { declaration }

          it "prevents change of schedule" do
            expect(subject.change_schedule).to be_falsey
            expect(subject).to have_error_count(1)
            expect(subject).to have_error(
              :cohort,
              :cannot_change_with_declarations,
              "You cannot change the '#/cohort' field when there are submitted, eligible, payable, or paid declarations in the new cohort",
            )

            application.reload
            expect(application.schedule).to eql(schedule)
            expect(application.cohort).to eql(cohort)
          end
        end

        context "with suffixed cohorts feature turned off" do
          before { allow(Feature).to receive(:suffixed_cohorts?).and_return(false) }

          let(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort: cohort) }

          it "chooses schedule from cohort with suffix of a" do
            expect(subject.change_schedule).to be_truthy
            application.reload
            expect(application.schedule).to eql(new_schedule)
            expect(application.cohort).to eql(cohort)
          end
        end
      end
    end
  end
end
