require "rails_helper"

RSpec.describe Course do
  describe "#eyl?" do
    context "when the course identifier is npq-early-years-leadership" do
      let(:course) { described_class.new(identifier: "npq-early-years-leadership") }

      it "returns true" do
        expect(course.eyl?).to be true
      end
    end

    context "when the course identifier is not npq-early-years-leadership" do
      let(:course) { described_class.new(identifier: "something") }

      it "returns false" do
        expect(course.eyl?).to be false
      end
    end
  end
end
