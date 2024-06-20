# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::ChangeSchedule do
  let(:cohort) { create(:cohort, :current) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, :sl) }
  let(:course_identifier) { course.identifier }
  let(:schedule) { create(:schedule, :npq_leadership_spring, cohort:) }
  let!(:application) { create(:application, :accepted, cohort:, lead_provider:, course:, schedule:) }

  let(:participant) { application.user }
  let(:participant_id) { participant.ecf_id }

  let(:new_cohort) { create(:cohort, :next) }
  let(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort: new_cohort) }
  let(:new_schedule_identifier) { new_schedule.identifier }

  let(:params) do
    {
      lead_provider:,
      participant:,
      course_identifier:,

      schedule_identifier: new_schedule_identifier,
      cohort: nil,
    }
  end

  subject { described_class.new(params) }

  describe "validations" do
    context "when validating a participant for a change schedule" do
      context "when the schedule is missing" do
        let(:new_schedule_identifier) { nil }

        it "is invalid and returns an error message" do
          expect(subject).to be_invalid

          expect(subject.errors.messages_for(:schedule_identifier)).to include("The property '#/schedule_identifier' must be present and correspond to a valid schedule")
        end
      end

      context "when the course identifier is missing" do
        let(:course_identifier) { nil }

        it "is invalid and returns an error message" do
          expect(subject).to be_invalid

          expect(subject.errors.messages_for(:course_identifier)).to include("The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.")
        end
      end

      context "when the course identifier is an invalid value" do
        let(:course_identifier) { "invalid-value" }

        it "is invalid and returns an error message" do
          expect(subject).to be_invalid

          expect(subject.errors.messages_for(:course_identifier)).to include("The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.")
        end
      end

      context "when the participant is missing" do
        let(:participant) { nil }

        it "is invalid and returns an error message" do
          expect(subject).to be_invalid

          expect(subject.errors.messages_for(:participant)).to include("Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.")
        end
      end

      context "when the schedule identifier change of the same type again" do
        before do
          create(:schedule, :npq_leadership_autumn, cohort:)
        end

        it "is invalid and returns an error message" do
          expect(subject.change_schedule).to be_truthy
          expect(subject).to be_invalid

          expect(subject.errors.messages_for(:schedule_identifier)).to include("Selected schedule is already on the profile")
        end
      end
    end

    context "when validating an application is not already withdrawn for a change schedule" do
      let(:application) { create(:application, :accepted, :withdrawn, cohort:, lead_provider:, course:, schedule:) }

      before do
        application
      end

      it "is invalid and returns an error message" do
        expect(subject).to be_invalid

        expect(subject.errors.messages_for(:participant)).to include("Cannot perform actions on a withdrawn participant")
      end
    end

    context "when the cohort is changing" do
      let(:params) do
        {
          lead_provider:,
          participant:,
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

        it "does not allow a change of schedule to be reversed if there are billable declarations in the new cohort" do
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
          expect(second_change_of_schedule).to be_invalid
          expect(second_change_of_schedule.errors.messages_for(:cohort)).to include("You cannot change the '#/cohort' field")
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
            it "is invalid and returns an error message" do
              expect(subject).to be_invalid

              expect(subject.errors.messages_for(:cohort)).to include("You cannot change the '#/cohort' field")
            end
          end
        end
      end

      context "when moving from funding cohort to funding cohort" do
        before do
          cohort.update!(funding_cap: true)
          new_cohort.update!(funding_cap: true)
          application.update!(funded_place: false, eligible_for_funding: true)
        end

        it "does not change funding place if original contract has a funded place" do
          expect(subject.change_schedule).to be_truthy
          application.reload
          expect(application.funded_place).to be_falsey
        end
      end

      context "when moving from non funding cohort to funding cohort" do
        let(:cohort) { create(:cohort, :current, funding_cap: false) }
        let(:new_cohort) { create(:cohort, :next, funding_cap: true) }
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
        before do
          cohort.update!(funding_cap: true)
          new_cohort.update!(funding_cap: false)
        end

        it "does not change the application to the new cohort" do
          expect(subject.change_schedule).to be_falsey

          expect(subject.errors.messages_for(:cohort)).to include("You cannot change the '#/cohort' field")
        end
      end
    end

    # TODO: when NPQ Contract has been migrated
    ###########################################
    # context "when lead provider has no contract for the cohort and course" do
    #   let(:new_cohort) { Cohort.previous }
    #
    #   before { npq_contract.update!(npq_course: create(:npq_specialist_course)) }
    #
    #   it "is invalid and returns an error message" do
    #     is_expected.to be_invalid
    #
    #     expect(subject.errors.messages_for(:cohort)).to include("You cannot change a participant to this cohort as you do not have a contract for the cohort and course. Contact the DfE for assistance.")
    #   end
    # end
    ###########################################
  end

  describe ".change_schedule" do
    context "when changing the schedule only" do
      let!(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }

      it "allows change of schedule" do
        expect(subject.change_schedule).to be_truthy
        application.reload
        expect(application.schedule).to eql(new_schedule)
        expect(application.cohort).to eql(cohort)
      end
    end

    context "when the cohort is changing" do
      let(:params) do
        {
          lead_provider:,
          participant:,
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
  end
end
