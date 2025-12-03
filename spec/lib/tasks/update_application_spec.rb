require "rails_helper"

RSpec.describe "update_application" do
  include_context "with default schedules"

  let(:cohort) { create(:cohort, :previous, :without_funding_cap) }

  shared_examples "outputting an error" do |message: "Application not found: "|
    it "outputs an error message" do
      expect { run_task }.to raise_error(RuntimeError, /#{message}/)
    end
  end

  describe "update_application:accept" do
    subject(:run_task) { Rake::Task["update_application:accept"].invoke(application.ecf_id) }

    after { Rake::Task["update_application:accept"].reenable }

    let(:application) { create(:application, :pending, cohort:) }

    it "accepts the application" do
      run_task
      expect(application.reload.lead_provider_approval_status).to eq "accepted"
    end

    context "when the application does not exist" do
      subject(:run_task) { Rake::Task["update_application:accept"].invoke(SecureRandom.uuid) }

      it_behaves_like "outputting an error"
    end
  end

  describe "update_application:revert_to_pending" do
    subject(:run_task) { Rake::Task["update_application:revert_to_pending"].invoke(application.ecf_id) }

    after { Rake::Task["update_application:revert_to_pending"].reenable }

    let(:application) { create(:application, :accepted) }

    it "reverts the application to pending" do
      run_task
      expect(application.reload.lead_provider_approval_status).to eq "pending"
    end

    context "when the application does not exist" do
      subject(:run_task) { Rake::Task["update_application:revert_to_pending"].invoke(SecureRandom.uuid) }

      it_behaves_like "outputting an error"
    end
  end

  describe "update_application:change_lead_provider" do
    subject(:run_task) { Rake::Task["update_application:change_lead_provider"].invoke(application.ecf_id, new_lead_provider.id) }

    after { Rake::Task["update_application:change_lead_provider"].reenable }

    let(:application) { create(:application, :accepted, lead_provider: LeadProvider.first) }
    let(:new_lead_provider) { LeadProvider.last }

    it "changes the lead provider of the application" do
      run_task
      expect(application.reload.lead_provider).to eq(new_lead_provider)
    end
  end

  describe "update_application:withdraw" do
    subject(:run_task) { Rake::Task["update_application:withdraw"].invoke(application.ecf_id, "started-in-error") }

    after { Rake::Task["update_application:withdraw"].reenable }

    let(:participant) { create(:user) }
    let(:application) { create(:application, :with_declaration, user: participant, cohort:) }

    it "withdraws the application" do
      run_task
      expect(application.reload.training_status).to eq "withdrawn"
    end
  end

  describe "update_application:change_cohort" do
    subject(:run_task) { Rake::Task["update_application:change_cohort"].invoke(application.ecf_id, new_cohort.start_year) }

    after { Rake::Task["update_application:change_cohort"].reenable }

    let(:application) { create(:application, cohort: Cohort.first) }
    let(:new_cohort) { create(:cohort, :next, :without_funding_cap) }

    it "changes the cohort of the application" do
      run_task
      expect(application.reload.cohort).to eq(new_cohort)
    end

    context "when the application has a schedule" do
      let(:application) { create(:application, :accepted, cohort: Cohort.first) }
      let!(:new_schedule) { Schedule.find_by(cohort: new_cohort, identifier: application.schedule.identifier) }
      let(:new_cohort) { Cohort.last }

      it "updates the schedule" do
        run_task
        expect(application.reload.schedule).to eq(new_schedule)
      end

      context "when the target schedule does not exist" do
        let(:new_cohort) { create(:cohort, start_year: 2029) }

        it "raises an error" do
          expect { run_task }.to raise_error(
            RuntimeError,
            "There is no schedule for the current course in the specified cohort",
          )
        end
      end
    end

    context "when the application does not exist" do
      subject(:run_task) { Rake::Task["update_application:change_cohort"].invoke(SecureRandom.uuid, new_cohort.start_year) }

      it_behaves_like "outputting an error"
    end

    context "when the cohort does not exist" do
      subject(:run_task) { Rake::Task["update_application:change_cohort"].invoke(application.ecf_id, "1000") }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Cohort not found: 1000")
      end
    end

    context "when the application has declarations" do
      let(:application) { create(:application, :with_declaration, cohort:) }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Cannot change cohort for an application with declarations")
      end

      context "when the override_declarations_check parameter is set" do
        subject(:run_task) { Rake::Task["update_application:change_cohort"].invoke(application.ecf_id, new_cohort.start_year, "true") }

        it "changes the cohort of the application" do
          run_task
          expect(application.reload.cohort).to eq(new_cohort)
        end
      end
    end
  end

  describe "update_application:update_schedule" do
    subject(:run_task) { Rake::Task["update_application:update_schedule"].invoke(application.ecf_id, schedule_identifier) }

    after { Rake::Task["update_application:update_schedule"].reenable }

    let(:application) { create(:application, :accepted, schedule: nil) }
    let(:schedule_identifier) { new_schedule.identifier }

    let(:new_schedule) { Schedule.where(cohort: application.cohort, course_group: application.course.course_group).last }

    it "updates the schedule of the application" do
      run_task

      expect(application.reload.schedule).to eq(new_schedule)
    end

    context "when the application does not exist" do
      subject(:run_task) { Rake::Task["update_application:update_schedule"].invoke(SecureRandom.uuid, schedule_identifier) }

      it_behaves_like "outputting an error"
    end

    context "when a schedule cannot be found for the specified schedule identifier" do
      subject(:run_task) { Rake::Task["update_application:update_schedule"].invoke(application.ecf_id, "this-schedule-does-not-exist") }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Schedule not found: this-schedule-does-not-exist")
      end
    end

    context "when the application has declarations" do
      let(:application) { create(:application, :with_declaration, cohort:) }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Cannot change schedule for an application with declarations")
      end
    end
  end

  describe "update_application:update_participant" do
    subject(:run_task) { Rake::Task["update_application:update_participant"].invoke(application.ecf_id, new_participant.ecf_id) }

    after { Rake::Task["update_application:update_participant"].reenable }

    let(:old_participant) { create(:user) }
    let(:new_participant) { create(:user) }
    let(:application) { create(:application, :with_declaration, user: old_participant, cohort:) }

    it "updates the participant of the application" do
      run_task
      expect(application.reload.user).to eq(new_participant)
    end

    context "when the application does not exist" do
      subject(:run_task) { Rake::Task["update_application:update_participant"].invoke(SecureRandom.uuid, new_participant.ecf_id) }

      it_behaves_like "outputting an error"
    end

    context "when the new participant does not exist" do
      subject(:run_task) { Rake::Task["update_application:update_participant"].invoke(application.ecf_id, SecureRandom.uuid) }

      it_behaves_like "outputting an error", message: "User not found: "
    end
  end

  describe "update_application:update_course" do
    subject(:run_task) { Rake::Task["update_application:update_course"].invoke(application.ecf_id, new_course.identifier) }

    after { Rake::Task["update_application:update_course"].reenable }

    let(:cohort) { create(:cohort, :current) }
    let(:schedule) { Schedule.where(cohort:, course_group: course.course_group).last }
    let(:application) { create(:application, course:, cohort:, schedule:) }
    let(:course) { create(:course, :leading_teaching_development) }
    let(:new_course) { create(:course, :leading_teaching) }

    it "updates the course of the application" do
      run_task

      expect(application.reload.course).to eq(new_course)
    end

    context "when the application does not exist" do
      subject(:run_task) { Rake::Task["update_application:update_course"].invoke(SecureRandom.uuid, new_course.identifier) }

      it_behaves_like "outputting an error"
    end

    context "when the course does not exist" do
      subject(:run_task) { Rake::Task["update_application:update_course"].invoke(application.ecf_id, "nonexistent-course-identifier") }

      it_behaves_like "outputting an error", message: "Course not found: nonexistent-course-identifier"
    end

    context "when the application has declarations" do
      let(:application) { create(:application, :with_declaration, course:, cohort:, schedule:) }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Cannot change course for an application with declarations")
      end
    end
  end
end
