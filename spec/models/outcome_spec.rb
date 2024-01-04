require "rails_helper"

RSpec.describe Outcome, type: :model do
  around do |test|
    described_class.const_set("MIGRATION_COMPLETED", true)
    test.run
    described_class.const_set("MIGRATION_COMPLETED", false)
  end

  describe "completion_date validations" do
    it "is valid with a future completion_date" do
      outcome = build :outcome, completion_date: Date.tomorrow
      puts outcome.inspect
      expect(outcome).to be_valid
    end

    it "is not valid with a past completion_date" do
      outcome = build :outcome, completion_date: Date.yesterday
      expect(outcome).not_to be_valid
    end

    it "is not valid with a nil completion_date" do
      outcome = build :outcome, completion_date: nil
      expect(outcome).not_to be_valid
    end
  end

  describe "state validations" do
    let(:valid_states) { %i[passed failed voided] }

    it "is valid with a state included in STATES" do
      valid_states.each do |state|
        outcome = described_class.new(state:)
        expect(outcome).to be_valid
      end
    end

    it "is not valid with a state not included in STATES" do
      outcome = described_class.new(state: :invalid_state)
      expect(outcome).not_to be_valid
    end

    it "is not valid with a nil state" do
      outcome = described_class.new(state: nil)
      expect(outcome).not_to be_valid
    end
  end
end
