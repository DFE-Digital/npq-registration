require "rails_helper"

RSpec.describe MilestonesStatement, type: :model do
  describe "paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "associations" do
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:statement) }
  end

  describe "validations" do
    describe "statement validation" do
      subject { described_class.new(milestone:, statement:) }

      let(:milestone) { create(:milestone) }
      let(:statement) { create(:statement, output_fee:) }

      context "when the statement is output_fee false" do
        let(:output_fee) { false }

        it { is_expected.not_to be_valid }
      end

      context "when the statement is output_fee true" do
        let(:output_fee) { true }

        it { is_expected.to be_valid }
      end

      context "when there are already statements for a different year/month" do
        let(:statement) { create(:statement, output_fee: true, year: 2023, month: 5) }

        before do
          other_statement = create(:statement, output_fee: true, year: 2023, month: 6)
          create(:milestones_statement, milestone:, statement: other_statement)
        end

        it { is_expected.not_to be_valid }

        context "when skip_statement_date_validation is true" do
          before { subject.skip_statement_date_validation = true }

          it { is_expected.to be_valid }
        end
      end
    end
  end
end
