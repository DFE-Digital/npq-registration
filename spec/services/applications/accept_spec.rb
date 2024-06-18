# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::Accept do
  let(:params) do
    {
      application:,
    }
  end

  subject(:service) do
    described_class.new(params)
  end

  describe "#accept" do
    let(:trn) { rand(1_000_000..9_999_999).to_s }
    let(:user) { create(:user, :with_verified_trn) }
    let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
    let(:course) { create(:course, :sl, course_group:) }
    let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
    let(:lead_provider) { create(:lead_provider) }
    let(:cohort) { create(:cohort, :current) }
    let(:cohort_next) { create(:cohort, :next) }

    let(:application) do
      create(
        :application,
        user:,
        course:,
        lead_provider:,
        cohort:,
        schedule:,
      )
    end

    before { schedule }

    describe "validations" do
      context "when the npq application is missing" do
        let(:application) {}

        it "is invalid and returns an error message" do
          expect(subject).to be_invalid

          expect(service.errors.messages_for(:application)).to include("The entered '#/application' is missing from your request. Check details and try again.")
        end
      end

      context "when the npq application is already accepted" do
        let(:application) { create(:application, :accepted) }

        it "is invalid and returns an error message" do
          expect(subject).to be_invalid

          expect(service.errors.messages_for(:application)).to include("This NPQ application has already been accepted")
        end
      end

      context "when the npq application is rejected" do
        let(:application) { create(:application, :rejected) }

        it "is invalid and returns an error message" do
          expect(subject).to be_invalid

          expect(service.errors.messages_for(:application)).to include("Once rejected an application cannot change state")
        end
      end

      context "when the existing data is invalid" do
        let(:application) { create(:application, cohort:, schedule:, course:) }

        it "throws ActiveRecord::RecordInvalid" do
          application.lead_provider_id = nil
          expect { service.accept }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context "when user applies for EHCO but has accepted ASO" do
      let(:other_course_group) { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }
      let(:course) { create(:course, :aso, course_group: other_course_group) }
      let(:npq_ehco) { create(:course, :ehco, course_group: other_course_group) }
      let!(:other_schedule) { create(:schedule, :npq_ehco_june, course_group: other_course_group, cohort:) }

      let(:other_application) do
        create(
          :application,
          user:,
          course: npq_ehco,
          lead_provider:,
          cohort:,
          schedule: other_schedule,
        )
      end

      before do
        service.accept
      end

      it "does not accept the EHCO application" do
        expect {
          described_class.new(application: other_application).accept
        }.not_to(change { other_application.reload.lead_provider_approval_status })
      end
    end

    context "when user has applied for the same course with another provider" do
      let(:other_lead_provider) { create(:lead_provider) }

      let(:other_application) do
        create(:application,
               user:,
               course:,
               lead_provider: other_lead_provider,
               cohort:)
      end

      before do
        application.save!
        other_application.save!
      end

      it "rejects other_application" do
        service.accept
        expect(application.reload.lead_provider_approval_status).to eql("accepted")
        expect(other_application.reload.lead_provider_approval_status).to eql("rejected")
      end
    end

    context "when accepting an application for a course that has already been accepted by another provider" do
      let(:other_lead_provider) { create(:lead_provider) }

      context "when the other npq applicaton belongs to the same participant identity user" do
        let(:other_application) do
          create(:application,
                 user:,
                 course:,
                 lead_provider: other_lead_provider,
                 cohort:)
        end

        let(:params) do
          {
            application: other_application,
          }
        end

        before do
          application.update!(lead_provider_approval_status: "accepted")
        end

        it "does not allow 2 applications with same course to be accepted" do
          expect {
            service.accept
          }.not_to(change { other_application.reload.lead_provider_approval_status })
        end

        it "attaches errors to the object" do
          service.accept

          expect(service.errors.messages_for(:application)).to include("The participant has already had an application accepted for this course.")
        end
      end

      context "when the other npq applicaton belongs to a different user but with the same teacher profile TRN" do
        let(:another_user) { create(:user, :with_verified_trn, trn: user.trn) }

        let(:other_application) do
          create(:application,
                 user: another_user,
                 course:,
                 lead_provider: other_lead_provider,
                 cohort:)
        end

        let(:params) do
          {
            application: other_application,
          }
        end

        before do
          application.update!(lead_provider_approval_status: "accepted")
        end

        it "does not allow 2 applications with same course to be accepted" do
          expect {
            service.accept
          }.not_to(change { other_application.reload.lead_provider_approval_status })
        end

        it "attaches errors to the object" do
          service.accept

          expect(service.errors.messages_for(:application)).to include("The participant has already had an application accepted for this course.")
        end
      end
    end

    context "when user has applied for different course" do
      let(:other_lead_provider) { create(:lead_provider) }
      let(:other_course) { create(:course, :eyl) }

      let(:other_application) do
        create(:application,
               user:,
               course: other_course,
               lead_provider: other_lead_provider,
               cohort:)
      end

      before do
        application.save!
        other_application.save!
      end

      it "does not reject the other course" do
        service.accept
        expect(application.reload.lead_provider_approval_status).to eql("accepted")
        expect(other_application.reload.lead_provider_approval_status).to eql("pending")
      end
    end

    context "when application has already been rejected" do
      before do
        application.lead_provider_approval_status = "rejected"
        application.save!
      end

      it "cannot then be accepted" do
        service.accept
        expect(application.reload).to be_rejected
        expect(service.errors.messages_for(:application)).to be_present
      end
    end

    context "when applying for 2022" do
      let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort: cohort_next) }
      let!(:application) do
        create(:application,
               user:,
               course:,
               lead_provider:,
               cohort: cohort_next)
      end

      context "when there is a previous cohort pending application" do
        let!(:previous_application) do
          create(:application,
                 user:,
                 course:,
                 lead_provider:,
                 cohort:)
        end

        it "does not affect 2021 application" do
          expect {
            service.accept
          }.to change { application.reload.lead_provider_approval_status }
           .and(not_change { previous_application.reload.lead_provider_approval_status })
        end
      end
    end

    describe "NPQ capping" do
      let(:cohort) { create(:cohort, :current, :with_funding_cap) }

      before do
        application.update!(eligible_for_funding: true)
      end

      context "when funded_place is true" do
        let(:params) { { application:, funded_place: true } }

        it "sets the funded place to true" do
          service.accept

          expect(application.reload.funded_place).to be_truthy
        end

        it "does not set funded place if eligible for funding is false" do
          application.update!(eligible_for_funding: false)

          service.accept
          expect(service.errors.messages_for(:application)).to include("The participant is not eligible for funding, so '#/funded_place' cannot be set to true.")
        end
      end

      context "when funded_place is false" do
        let(:params) { { application:, funded_place: false } }

        it "sets the funded place to false" do
          service.accept

          expect(application.reload.funded_place).to be_falsey
        end
      end

      context "when funded_place is nil" do
        let(:params) { { application:, funded_place: nil } }

        context "when funding_cap is true" do
          it "returns funding_place is required error" do
            service.accept
            expect(service.errors.messages_for(:application)).to include("Set '#/funded_place' to true or false.")
          end
        end

        context "when funding_cap is false" do
          let(:cohort) { create(:cohort, :current) }

          it "does not validate funded_place" do
            service.accept
            expect(service.errors.messages_for(:application)).to be_empty
          end
        end
      end
    end

    describe "changing schedule on accept" do
      let(:cohort) { create(:cohort, :current) }
      let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
      let(:course) { create(:course, :sl, course_group:) }
      let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }

      let(:application) do
        create(
          :application,
          :pending,
          user:,
          course:,
          lead_provider:,
          cohort:,
          schedule:,
        )
      end

      let(:params) { { application:, schedule_identifier: new_schedule.identifier } }

      before { new_schedule }

      context "when changing to correct schedule" do
        let(:new_schedule) { create(:schedule, :npq_leadership_spring, course_group:, cohort:) }

        it "changes schedule successfully" do
          expect(ApplicationState.count).to be(0)
          expect(service.application.lead_provider_approval_status).to eql("pending")

          expect(service.accept).to be_truthy
          expect(service.application.lead_provider_approval_status).to eql("accepted")
          expect(service.application.schedule).to eql(new_schedule)

          application_state = ApplicationState.first
          expect(application_state.lead_provider).to eql(lead_provider)
          expect(application_state.application).to eql(application)
          expect(application_state).to be_active
        end
      end

      context "when changing to wrong schedule" do
        let(:new_course_group) { CourseGroup.find_by(name: "specialist") || create(:course_group, name: "specialist") }
        let(:new_course) { create(:course, :sl, course_group: new_course_group) }
        let(:new_schedule) { create(:schedule, :npq_leadership_spring, course_group: new_course_group, cohort:) }

        it "returns validation error" do
          expect(service.accept).to be_falsey
          expect(service.errors.messages_for(:schedule_identifier)).to include("Selected schedule is not valid for the course")
        end
      end
    end
  end
end
