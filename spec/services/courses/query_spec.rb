require "rails_helper"

RSpec.describe Courses::Query do
  describe "#courses" do
    it "returns all courses" do
      query = Courses::Query.new

      expect(query.courses).not_to be_empty
      expect(query.courses).to match_array(Course.all)
    end

    it "orders courses by name in ascending order" do
      query = Courses::Query.new
      course_names = query.courses.map(&:name)
      expect(course_names).to eq(course_names.sort)
    end
  end

  describe "#course" do
    it "returns the course" do
      course = create(:course)
      query = Courses::Query.new
      expect(query.course(id: course.id)).to eq(course)
    end

    it "raises an error if the course does not exist" do
      query = Courses::Query.new
      expect { query.course(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
