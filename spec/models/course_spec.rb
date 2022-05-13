require "rails_helper"

RSpec.describe Course do
  describe "#eyl?" do
    context "when the course name is NPQEYL" do
      let(:course) { described_class.new(name: "NPQ Early Years Leadership (NPQEYL)") }

      it "returns true" do
        expect(course.eyl?).to be true
      end
    end

    context "when the course name is not NPQEYL" do
      let(:course) { described_class.new(name: "something") }

      it "returns false" do
        expect(course.eyl?).to be false
      end
    end
  end
end
