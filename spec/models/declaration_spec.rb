require "rails_helper"

RSpec.describe Declaration, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:application).required }
    it { is_expected.to have_many(:outcomes) }
    it { is_expected.to have_many(:statement_items) }
  end

  describe "validations" do

    describe "state validations" do
      let(:valid_states) { %w[submitted eligible ineligible payable voided paid awaiting_clawback clawed_back] }

      it "is valid with a state included in STATES" do
        valid_states.each do |state|
          declaration = build(:declaration, state:)
          expect(declaration).to be_valid
        end
      end

      it "is not valid with a state not included in STATES" do
        declaration = build :declaration, state: "invalid_state"
        expect(declaration).not_to be_valid
      end

      it "is not valid with a nil state" do
        declaration = build :declaration, state: nil
        expect(declaration).not_to be_valid
      end
    end
  end
end
