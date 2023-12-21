require "rails_helper"

RSpec.describe StatementItem, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:statement_id) }
    it { is_expected.to validate_presence_of(:declaration_id) }
    it { is_expected.to validate_inclusion_of(:state).in_array(StatementItem::STATES) }

    describe "clawed_back_by validation" do
      context "when state is clawed_back" do
        it "is invalid without a clawed_back_by" do
          statement_item = described_class.new(state: "clawed_back", clawed_back_by: nil)

          expect(statement_item).not_to be_valid
          expect(statement_item.errors[:clawed_back_by]).to include("can't be blank")
        end

        it "is valid with a clawed_back_by" do
          clawed_back_by_item = described_class.create!(state: "eligible")
          statement_item = described_class.new(state: "clawed_back", clawed_back_by: clawed_back_by_item)

          expect(statement_item).to be_valid
        end
      end

      context "when state is not clawed_back" do
        it "is valid without a clawed_back_by" do
          statement_item = described_class.new(state: "eligible", clawed_back_by: nil)

          expect(statement_item).to be_valid
        end
      end
    end
  end
end
