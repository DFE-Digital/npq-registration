require "rails_helper"

RSpec.describe StatementHelper, type: :helper do
  describe "#statement_name" do
    subject { statement_name(statement) }

    let(:statement) { build(:statement, month: 3, year: 2024) }

    it { is_expected.to eq("March 2024") }
  end
end
