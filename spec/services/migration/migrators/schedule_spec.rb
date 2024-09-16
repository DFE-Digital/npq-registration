require "rails_helper"

RSpec.describe Migration::Migrators::Schedule do
  it_behaves_like "a migrator", :schedule, %i[cohort course] do
    let(:ecf_class) { Migration::Ecf::Finance::Schedule }

    def create_ecf_resource
      create(:ecf_migration_schedule_npq_support).tap do |schedule|
        create(:ecf_migration_milestone, schedule:)
      end
    end

    def create_npq_resource(ecf_resource)
      create(:cohort, start_year: ecf_resource.cohort.start_year)
      create(:course_group, name: :support)

      create(:schedule, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # Schedule milestones contain different dates
      schedule = create(:ecf_migration_schedule_npq_support)
      create(:ecf_migration_milestone, schedule:, start_date: 1.day.ago)
      create(:ecf_migration_milestone, schedule:, start_date: 2.days.ago)
    end

    describe "#call" do
      it "sets the applies from/to of the schedule" do
        ecf_milestone = ecf_resource1.milestones.first
        schedule = Schedule.find_by!(ecf_id: ecf_resource1.id)

        expect { instance.call }.to change { schedule.reload.applies_from }.to(ecf_milestone.start_date)
          .and change { schedule.applies_to }.to(ecf_milestone.payment_date)
      end

      it "sets the allowed declaration types of the schedule" do
        ecf_milestones = ecf_resource1.milestones
        schedule = Schedule.find_by!(ecf_id: ecf_resource1.id)

        expect { instance.call }.to change { schedule.reload.allowed_declaration_types }.to(ecf_milestones.pluck(:declaration_type))
      end

      context "when the schedule type cannot be mapped to a course group" do
        it "records a failure" do
          schedule = create(:ecf_migration_schedule)
          create(:ecf_migration_milestone, schedule:)

          instance.call

          expect(failure_manager).to have_received(:record_failure).once.with(schedule, /Validation failed: Course group not found for schedule/)
        end
      end

      it "creates a new schedule in NPQ when a matching schedule does not exist" do
        create(:ecf_migration_schedule_npq_support).tap do |schedule|
          create(:ecf_migration_milestone, schedule:)
        end

        expect { instance.call }.to change(Schedule, :count).by(1)
      end

      {
        ecf_migration_schedule_npq_support: "support",
        ecf_migration_schedule_npq_specialist: "specialist",
        ecf_migration_schedule_npq_ehco: "ehco",
        ecf_migration_schedule_npq_leadership: "leadership",
      }.each do |scehdule_factory, course_group_name|
        context "when there are #{scehdule_factory} schedules" do
          it "creates a new schedule in NPQ with the correct course group" do
            ecf_schedule = create(scehdule_factory).tap do |schedule| # rubocop:disable Rails/SaveBang
              create(:ecf_migration_milestone, schedule:)
            end

            expect { instance.call }.to change(Schedule, :count).by(1)

            schedule = Schedule.find_by(ecf_id: ecf_schedule.id)
            expect(schedule.course_group.name).to eq(course_group_name)
          end
        end
      end
    end
  end
end
