require "rails_helper"

RSpec.describe "course cohort providers rake tasks" do
  describe "course_cohort_providers:load" do
    subject(:run_task) { Rake::Task["course_cohort_providers:load"].invoke(cohort_identifier, csv_file_path, dry_run) }

    let(:dry_run) { nil }
    let(:cohort) { create(:cohort, :current) }
    let(:cohort_identifier) { cohort.identifier }
    let(:headship_course) { create(:course, :headship) }
    let(:csv_file_path) { csv_file.path }
    let(:updater) { instance_double(CourseCohortProviders::Updater, call: nil) }

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
      allow(CourseCohortProviders::Updater).to receive(:new).and_return(updater)
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

      it "calls the updater" do
        expect(CourseCohortProviders::Updater).to receive(:new).with(
          cohort:,
          course_to_provider_csv: csv_file_path,
          dry_run: false,
          logger: Rails.logger,
        )
        expect(updater).to receive(:call)
        run_task
      end
    end

    context "when dry run is true" do
      it "calls the updater" do
        expect(CourseCohortProviders::Updater).to receive(:new).with(
          cohort:,
          course_to_provider_csv: csv_file_path,
          dry_run: true,
          logger: Rails.logger,
        )
        expect(updater).to receive(:call)
        run_task
      end
    end
  end
end
