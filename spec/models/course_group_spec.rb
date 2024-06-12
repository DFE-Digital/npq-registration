require "rails_helper"

RSpec.describe CourseGroup, type: :model do
  let(:cohort) { create(:cohort, :current) }
  let(:schedule_date) { Date.current }

  subject { build(:course_group) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name).with_message("Enter a unique course group name") }
    it { is_expected.to validate_uniqueness_of(:name).with_message("Course name already exist, enter a unique name") }
  end

  describe "associations" do
    it { is_expected.to have_many(:courses) }
  end

  describe "#schedule_for" do
    context "when NPQ Leadership" do
      subject { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }

      it "calls the correct service class" do
        service = instance_double(CourseGroups::Leadership)
        expect(service).to receive(:schedule).and_return(true)
        expect(CourseGroups::Leadership).to receive(:new).with(course_group: subject, cohort:, schedule_date:).and_return(service)
        expect(subject.schedule_for(cohort:, schedule_date:)).to eq(true)
      end
    end

    context "when NPQ Specialist" do
      subject { CourseGroup.find_by(name: "specialist") || create(:course_group, name: "specialist") }

      it "calls the correct service class" do
        service = instance_double(CourseGroups::Specialist)
        expect(service).to receive(:schedule).and_return(true)
        expect(CourseGroups::Specialist).to receive(:new).with(course_group: subject, cohort:, schedule_date:).and_return(service)
        expect(subject.schedule_for(cohort:, schedule_date:)).to eq(true)
      end
    end

    context "when NPQ Support" do
      subject { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

      it "calls the correct service class" do
        service = instance_double(CourseGroups::Support)
        expect(service).to receive(:schedule).and_return(true)
        expect(CourseGroups::Support).to receive(:new).with(course_group: subject, cohort:).and_return(service)
        expect(subject.schedule_for(cohort:, schedule_date:)).to eq(true)
      end
    end

    context "when NPQ Ehco" do
      subject { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }

      it "calls the correct service class" do
        service = instance_double(CourseGroups::Ehco)
        expect(service).to receive(:schedule).and_return(true)
        expect(CourseGroups::Ehco).to receive(:new).with(course_group: subject, cohort:, schedule_date:).and_return(service)
        expect(subject.schedule_for(cohort:, schedule_date:)).to eq(true)
      end
    end
  end
end
