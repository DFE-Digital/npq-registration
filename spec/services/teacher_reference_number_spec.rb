# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeacherReferenceNumber do
  describe "#formatted_trn" do
    it "removes non-numeric characters" do
      expect(described_class.new("RP22/ 21 1 33").formatted_trn).to eq("2221133")
    end

    it "zero pads the value to 7-digits" do
      expect(described_class.new("RP99/123").formatted_trn).to eq("0099123")
    end

    context "when the original value does not have enough digits" do
      it "returns nil" do
        expect(described_class.new("QWERTY123").formatted_trn).to be_nil
      end
    end

    context "when the original value has too many digits" do
      it "returns nil" do
        expect(described_class.new("QWERTY123456789").formatted_trn).to be_nil
      end
    end

    context "when the original value has no digits" do
      it "returns nil" do
        expect(described_class.new("QWERTY").formatted_trn).to be_nil
      end
    end
  end
end
