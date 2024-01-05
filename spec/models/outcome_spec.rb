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
    let(:valid_states) { %w[passed failed voided] }

    it "is valid with a state included in STATES" do
      valid_states.each do |state|
        puts state
        outcome = build(:outcome, state:)

        expect(outcome).to be_valid
      end
    end

    it "is not valid with a state not included in STATES" do
      outcome = build :outcome, state: "invalid_state"

      expect(outcome).not_to be_valid
    end

    it "is not valid with a nil state" do
      outcome = build :outcome, state: nil

      expect(outcome).not_to be_valid
    end
  end
end
