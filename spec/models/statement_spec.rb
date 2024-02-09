require "rails_helper"

RSpec.describe Statement, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:cohort).required }
    it { is_expected.to belong_to(:lead_provider).required }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:statement_items) }
    it { is_expected.to have_many(:contracts) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:month).is_in(1..12).only_integer }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_in(2020..2050) }

    describe "Validation for statement items count" do
      let(:statement) { create(:statement) }

      context "when the statement has two or fewer statement items" do
        it "is valid" do
          create_list(:statement_item, 2, statement:)
          expect(statement.valid?).to be true
        end
      end

      context "when the statement has more than two statement items" do
        it "is not valid" do
          create_list(:statement_item, 3, statement:) # Adjust to match your factory name and attributes

          expect(statement.valid?).to be false
          expect(statement.errors[:statement_items]).to include("cannot have more than two items")
        end
      end
    end
  end
end
