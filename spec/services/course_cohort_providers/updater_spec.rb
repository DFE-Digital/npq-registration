require "rails_helper"

RSpec.describe CourseCohortProviders::Updater do
  let(:cohort) { create(:cohort, :current) }
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

  describe ".call" do
    subject { described_class.new(cohort:, course_to_provider_csv: csv_file_path, dry_run:).call }

    context "when dry run is false" do
      let(:dry_run) { false }

      it "creates course cohorts" do
        subject
        expect(cohort.course_cohorts.pluck(:course_id)).to contain_exactly(headship_course.id)
      end

      it "creates course cohort providers" do
        subject
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
      let(:dry_run) { true }

      it "does not create course cohorts" do
        subject
        expect(CourseCohort.count).to eq 0
      end

      it "does not create course cohort providers" do
        subject
        expect(CourseCohortProvider.count).to eq 0
      end
    end
  end
end
