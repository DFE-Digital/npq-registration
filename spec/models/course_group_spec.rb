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
        allow(service).to receive(:schedule).and_return(true)
        expect(service).to receive(:schedule)

        allow(CourseGroups::Leadership).to receive(:new).with(course_group: subject, cohort:, schedule_date:).and_return(service)
        expect(CourseGroups::Leadership).to receive(:new).with(course_group: subject, cohort:, schedule_date:)

        expect(subject.schedule_for(cohort:, schedule_date:)).to be(true)
      end
    end

    context "when NPQ Specialist" do
      subject { CourseGroup.find_by(name: "specialist") || create(:course_group, name: "specialist") }

      it "calls the correct service class" do
        service = instance_double(CourseGroups::Specialist)
        allow(service).to receive(:schedule).and_return(true)
        expect(service).to receive(:schedule)

        allow(CourseGroups::Specialist).to receive(:new).with(course_group: subject, cohort:, schedule_date:).and_return(service)
        expect(CourseGroups::Specialist).to receive(:new).with(course_group: subject, cohort:, schedule_date:)

        expect(subject.schedule_for(cohort:, schedule_date:)).to be(true)
      end
    end

    context "when NPQ Support" do
      subject { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

      it "calls the correct service class" do
        service = instance_double(CourseGroups::Support)
        allow(service).to receive(:schedule).and_return(true)
        expect(service).to receive(:schedule)

        allow(CourseGroups::Support).to receive(:new).with(course_group: subject, cohort:).and_return(service)
        expect(CourseGroups::Support).to receive(:new).with(course_group: subject, cohort:)

        expect(subject.schedule_for(cohort:, schedule_date:)).to be(true)
      end
    end

    context "when NPQ Ehco" do
      subject { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }

      it "calls the correct service class" do
        service = instance_double(CourseGroups::Ehco)
        allow(service).to receive(:schedule).and_return(true)
        expect(service).to receive(:schedule)

        allow(CourseGroups::Ehco).to receive(:new).with(course_group: subject, cohort:, schedule_date:).and_return(service)
        expect(CourseGroups::Ehco).to receive(:new).with(course_group: subject, cohort:, schedule_date:)

        expect(subject.schedule_for(cohort:, schedule_date:)).to be(true)
      end
    end
  end

  describe "scopes" do
    describe ".leadership_or_specialist" do
      let!(:leadership_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
      let!(:specialist_group) { CourseGroup.find_by(name: "specialist") || create(:course_group, name: "specialist") }

      before { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

      it "returns leadership and specialist groups only" do
        expect(described_class.leadership_or_specialist).to contain_exactly(leadership_group, specialist_group)
      end
    end
  end
end
