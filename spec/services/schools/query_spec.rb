require "rails_helper"

RSpec.describe Schools::Query do
  describe "#schools" do
    it "returns all schools" do
      school1 = create(:school)
      school2 = create(:school)

      query = Schools::Query.new
      expect(query.schools).to contain_exactly(school1, school2)
    end

    it "orders schools by name in ascending order" do
      school1 = create(:school, name: "C School")
      school2 = create(:school, name: "A school")
      school3 = create(:school, name: "B school")

      query = Schools::Query.new
      expect(query.schools).to eq([school2, school3, school1])
    end
  end

  describe "#school" do
    it "returns the school" do
      school = create(:school)

      query = Schools::Query.new
      expect(query.school(id: school.id)).to eq(school)
    end

    it "raises an error if the school does not exist" do
      query = Schools::Query.new
      expect { query.school(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
