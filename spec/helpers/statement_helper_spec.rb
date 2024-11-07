require "rails_helper"

RSpec.describe StatementHelper, type: :helper do
  describe "#statement_name" do
    subject { statement_name(statement) }

    let(:statement) { build(:statement, month: 3, year: 2024) }

    it { is_expected.to eq("March 2024") }
  end

  describe "#number_to_pounds" do
    subject { number_to_pounds(number) }

    context "with integer" do
      let(:number) { 10 }

      it { is_expected.to eq "£10.00" }
    end

    context "with long float" do
      let(:number) { 9.87654321 }

      it { is_expected.to eq "£9.88" }
    end
  end
end
