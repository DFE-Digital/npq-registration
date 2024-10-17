# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dqt::TeacherRecord, type: :model do
  let(:state_name) { "Active" }
  let(:attributes) do
    {
      trn: "123456",
      state_name:,
      name: "John Doe",
      dob: Date.new(1990, 1, 1).iso8601,
      ni_number: "AB123456C",
      active_alert: true,
    }
  end

  subject { described_class.new(attributes) }

  describe "attributes" do
    it "returns correct attributes" do
      expect(subject.trn).to eq("123456")
      expect(subject.state_name).to eq("Active")
      expect(subject.name).to eq("John Doe")
      expect(subject.dob).to eq("1990-01-01")
      expect(subject.ni_number).to eq("AB123456C")
      expect(subject.active_alert).to be(true)
    end
  end

  describe "#active?" do
    context "when the state_name is 'Active'" do
      let(:state_name) { "Active" }

      it "returns true" do
        expect(subject.active?).to be(true)
      end
    end

    context "when the state_name is not 'Active'" do
      let(:state_name) { "Inactive" }

      it "returns false" do
        expect(subject.active?).to be(false)
      end
    end
  end
end
