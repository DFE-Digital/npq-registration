require "rails_helper"

RSpec.describe Courses::Query do
  describe "#courses" do
    it "returns all courses" do
      query = Courses::Query.new

      expect(query.courses).not_to be_empty
      expect(query.courses).to contain_exactly(*Course.all)
    end

    it "orders courses by name in ascending order" do
      query = Courses::Query.new
      course_names = query.courses.map(&:name)

      # Postgres orders alphabetically regardless of case but
      # Ruby orders by the hex value meaning lowercase entries
      # come last, so we fix the case before sorting. This is
      # triggered by 'NPQ for Senco 1'
      sorted_course_names = course_names.sort_by(&:downcase)

      expect(course_names).to eq(sorted_course_names)
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
