require "rails_helper"

RSpec.describe CourseGroups::Support do
  let(:cohort) { create(:cohort, :current) }
  let(:course_group) { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

  subject { described_class.new(course_group:, cohort:) }

  describe "#schedule" do
    let!(:schedule) { create(:schedule, :npq_aso_december, course_group:, cohort:) }

    it "returns NPQ ASO December schedule" do
      expect(subject.schedule).to eql(schedule)
    end
  end
end
