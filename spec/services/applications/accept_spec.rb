# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::Accept, :with_default_schedules, type: :model do
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
    let(:course_group) { create(:course_group, name: "leadership") }
    let(:course) { create(:course, :senior_leadership, course_group:) }
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
      )
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }

      context "when the npq application is already accepted" do
        let(:application) { create(:application, :accepted) }

        it { is_expected.to have_error(:application, :has_already_been_accepted, "This NPQ application has already been accepted") }
      end

      context "when the npq application is rejected" do
        let(:application) { create(:application, :rejected) }

        it { is_expected.to have_error(:application, :cannot_change_from_rejected, "Once rejected an application cannot change state") }
      end

      context "when the existing data is invalid" do
        let(:application) { create(:application, cohort:, course:) }

        it "throws ActiveRecord::RecordInvalid" do
          application.lead_provider_id = nil
          expect { service.accept }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context "when user applies for EHCO but has accepted ASO" do
      let(:other_course_group) { create(:course_group, name: "ehco") }
      let(:course) { create(:course, :additional_support_offer, course_group: other_course_group) }
      let(:npq_ehco) { create(:course, :early_headship_coaching_offer, course_group: other_course_group) }

      let(:other_application) do
        create(
          :application,
          user:,
          course: npq_ehco,
          lead_provider:,
          cohort:,
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

      context "when the other npq applicaton belongs to the same participant" do
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
          expect(service).to have_error(:application, :has_another_accepted_application, "The participant has already had an application accepted for this course.")
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
          expect(service).to have_error(:application, :has_another_accepted_application, "The participant has already had an application accepted for this course.")
        end
      end
    end

    context "when user has applied for different course" do
      let(:other_lead_provider) { create(:lead_provider) }
      let(:other_course) { create(:course, :early_years_leadership) }

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
        expect(service).to have_error(:application, :cannot_change_from_rejected, "Once rejected an application cannot change state")
      end
    end

    context "when applying for 2022" do
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
          expect(service).to have_error(:application, :not_eligible_for_funded_place, "The participant is not eligible for funding, so '#/funded_place' cannot be set to true.")
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
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end

        context "when funding_cap is false" do
          let(:cohort) { create(:cohort, :current) }

          it "does not validate funded_place" do
            service.accept
            expect(service.errors.messages_for(:funded_place)).to be_empty
          end
        end
      end

      context "when funded_place is a string" do
        context "when funded_place is `true`" do
          let(:params) { { application:, funded_place: "true" } }

          it "returns funding_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end

        context "when funded_place is `false`" do
          let(:params) { { application:, funded_place: "false" } }

          it "returns funding_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end

        context "when funded_place is `null`" do
          let(:params) { { application:, funded_place: "null" } }

          it "returns funding_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end

        context "when funded_place is an empty string" do
          let(:params) { { application:, funded_place: "" } }

          it "returns funding_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end
      end
    end

    describe "changing schedule on accept" do
      let(:cohort) { create(:cohort, :current) }
      let(:course_group) { create(:course_group, name: "leadership") }
      let(:course) { create(:course, :senior_leadership, course_group:) }

      let(:application) do
        create(
          :application,
          :pending,
          user:,
          course:,
          lead_provider:,
          cohort:,
        )
      end

      let(:params) { { application:, schedule_identifier: new_schedule.identifier } }

      context "when changing to correct schedule" do
        let!(:new_schedule) { create(:schedule, :npq_leadership_spring, course_group:, cohort:) }

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

      context "when changing to a schedule that's not correct for the application course" do
        let!(:new_schedule) { create(:schedule, :npq_ehco_november, cohort:) }

        it "returns validation error" do
          expect(service.accept).to be_falsey
          expect(service.application.schedule).not_to eql(new_schedule)
          expect(service.errors.messages_for(:schedule_identifier)).to include("Selected schedule is not valid for the course")
        end
      end

      context "when a new schedule is not found given a wrong identifier" do
        let(:params) { { application:, schedule_identifier: "any-schedule" } }

        it "returns validation error" do
          expect(service.accept).to be_falsey
          expect(service).to have_error(:schedule_identifier, :invalid_for_course, "Selected schedule is not valid for the course")
        end
      end
    end
  end
end
