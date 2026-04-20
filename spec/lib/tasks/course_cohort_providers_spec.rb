require "rails_helper"

RSpec.describe "course cohort providers rake tasks" do
  describe "course_cohort_providers:load" do
    subject(:run_task) { Rake::Task["course_cohort_providers:load"].invoke(cohort_identifier, csv_file_path, dry_run) }

    let(:dry_run) { nil }
    let(:cohort) { create(:cohort, :current) }
    let(:cohort_identifier) { cohort.identifier }
    let(:headship_course) { create(:course, :headship) }
    let(:csv_file_path) { csv_file.path }

    let(:csv_file) do
      tempfile <<~CSV
        course_identifier, lead_provider_name
        npq-headship, Ambition Institute
        npq-headship, Best Practice Network
      CSV
    end

    before do
      cohort
      headship_course
    end

    after do
      Rake::Task["course_cohort_providers:load"].reenable
    end

    context "when cohort identifier is missing" do
      subject(:run_task) { Rake::Task["course_cohort_providers:load"].invoke }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Missing required argument: cohort_identifier")
      end
    end

    context "when the cohort is not found" do
      let(:cohort_identifier) { "9999a" }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Cohort not found with identifier: 9999a")
      end
    end

    context "when course to provider CSV is missing" do
      let(:csv_file_path) { nil }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Missing required argument: course_to_provider_csv")
      end
    end

    context "when dry run is false" do
      let(:dry_run) { "false" }

      it "creates course cohorts" do
        run_task
        expect(cohort.course_cohorts.pluck(:course_id)).to contain_exactly(headship_course.id)
      end

      it "creates course cohort providers" do
        run_task
        course_cohort = cohort.course_cohorts.find_by(course: headship_course)
        expect(headship_course.course_cohort_providers.where(course_cohort:).pluck(:lead_provider_id)).to(
          contain_exactly(
            LeadProvider.find_by(name: "Ambition Institute").id,
            LeadProvider.find_by(name: "Best Practice Network").id,
          ),
        )
      end
    end

    context "when dry run is true" do
      it "does not create course cohorts" do
        run_task
        expect(CourseCohort.count).to eq 0
      end

      it "does not create course cohort providers" do
        run_task
        expect(CourseCohortProvider.count).to eq 0
      end
    end
  end
end
