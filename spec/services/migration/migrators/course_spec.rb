require "rails_helper"

RSpec.describe Migration::Migrators::Course do
  before { ::Course.destroy_all }

  it_behaves_like "a migrator", :course, [] do
    def create_ecf_resource
      existing_identifiers = Course.all.pluck(:identifier)
      identifier = Courses::DEFINITIONS.map { |h| h[:identifier] }.excluding(existing_identifiers).sample
      create(:ecf_migration_npq_course, identifier:)
    end

    def create_npq_resource(ecf_resource)
      create(:course, identifier: ecf_resource.identifier, ecf_id: ecf_resource.id, course_group: nil)
    end

    def setup_failure_state
      # ECF course we don't have a group mapping for.
      create(:ecf_migration_npq_course, name: "not-recognised")
    end

    describe "#call" do
      it "sets the created Course attributes correctly" do
        instance.call
        course = Course.find_by(ecf_id: ecf_resource1.id)
        expect(course).to have_attributes(ecf_resource1.attributes.slice("identifier", "name"))
        expect(course.course_group.name).to eq(Courses::DEFINITIONS.find { |d| d[:identifier] == ecf_resource1.identifier }[:course_group_name])
      end

      it "creates the course groups" do
        Course.destroy_all
        CourseGroup.destroy_all

        expect { instance.call }.to change(CourseGroup, :count).by(described_class::COURSE_GROUP_NAMES.count)

        expect(CourseGroup.where(name: described_class::COURSE_GROUP_NAMES).count).to eq(described_class::COURSE_GROUP_NAMES.count)
      end
    end
  end
end
