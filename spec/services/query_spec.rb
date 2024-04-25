require "rails_helper"

RSpec.describe(Query) do
  describe "#extract_conditions" do
    context "when called with a string with one value" do
      it "returns an array containing only the value" do
        expect(Query.new.extract_conditions("hello")).to eql(%w[hello])
      end
    end

    context "when called with a string with a comma separated list of values" do
      it "returns an array containing all the values" do
        expect(Query.new.extract_conditions("hello,goodbye")).to eql(%w[hello goodbye])
      end
    end

    context "when called with an array of values" do
      it "returns the array" do
        input = ["hello", nil, "goodbye"]

        expect(Query.new.extract_conditions(input)).to eql(%w[hello goodbye])
      end
    end

    context "when called with a value that's not an array or string" do
      it "returns the value" do
        expect(Query.new.extract_conditions(nil)).to eq(nil)
        expect(Query.new.extract_conditions(1)).to eq(1)
        expect(Query.new.extract_conditions(2.0)).to eq(2.0)
        expect(Query.new.extract_conditions(/three/)).to eq(/three/)
      end
    end
  end
end
