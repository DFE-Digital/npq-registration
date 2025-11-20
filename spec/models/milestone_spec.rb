require "rails_helper"

RSpec.describe Milestone, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:milestones_statements) }
    it { is_expected.to have_many(:statements).through(:milestones_statements) }
    it { is_expected.to belong_to(:schedule) }
  end

  describe "default scope" do
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
      expect(Milestone.all).to eq([started, retained_1, retained_2, completed])
    end
  end
end
