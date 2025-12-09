require "rails_helper"

RSpec.describe Milestone, type: :model do
  describe "paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "associations" do
    it { is_expected.to have_many(:milestone_statements) }
    it { is_expected.to have_many(:statements).through(:milestone_statements) }
    it { is_expected.to belong_to(:schedule) }
  end

  describe "validations" do
    context "when creating a milestone for a declaration type not in the schedule's allowed_declaration_types" do
      subject(:milestone) { build(:milestone, declaration_type: "retained-1", schedule:, statements: [statement]) }

      let(:schedule) { create(:schedule, allowed_declaration_types: %w[started completed]) }
      let(:statement) { create(:statement) }

      it { is_expected.to have_error(:declaration_type, :inclusion, "The declaration type should be one of the ones allowed by the schedule") }
    end
  end

  describe "#in_declaration_type_order" do
    let(:schedule) { create(:schedule) }
    let(:started) { Milestone.create!(declaration_type: "started", schedule:) }
    let(:retained_1) { Milestone.create!(declaration_type: "retained-1", schedule:) }
    let(:retained_2) { Milestone.create!(declaration_type: "retained-2", schedule:) }
    let(:completed) { Milestone.create!(declaration_type: "completed", schedule:) }

    before do
      # create deliberately out of order
      retained_2
      completed
      started
      retained_1
    end

    it "orders by declaration_type according to DECLARATION_TYPES" do
      expect(Milestone.all.in_declaration_type_order).to eq([started, retained_1, retained_2, completed])
    end
  end
end
