require "rails_helper"

class SampleQuery
  include Queries::ConditionFormats
end

RSpec.describe "Schools::Query" do
  let(:object) { SampleQuery.new }

  describe "#extract_conditions" do
    context "when the input is a string" do
      it "returns an array containing the string" do
        expect(object.extract_conditions("one")).to eql(%w[one])
      end

      it "splits on comma" do
        expect(object.extract_conditions("one,two,three")).to eql(%w[one two three])
      end
    end

    context "when the input is an array" do
      it "returns the compacted input" do
        expect(object.extract_conditions(["one", nil, "two"])).to eql(%w[one two])
      end
    end

    context "when the input is anything else" do
      [0, 0.0, Time.zone.today, Time.zone.now, /sample/, true, false].each do |input|
        it "#{input.class.name} arguments are returned untouched" do
          expect(object.extract_conditions(input)).to eql(input)
        end
      end
    end

    context "when an allowlist is provided" do
      let(:allowlist) { %w[one three] }

      it "returns an array containing only the allowed values when the input is a string" do
        expect(object.extract_conditions("one", allowlist:)).to eql(%w[one])
      end

      it "returns an array containing only the allowed values when the input is an array" do
        expect(object.extract_conditions(%w[one two three], allowlist:)).to eql(%w[one three])
      end

      it "returns the input when it is anything else if it is in the allowlist" do
        expect(object.extract_conditions(123, allowlist: [123, 456])).to eq(123)
      end
    end
  end
end
