require "rails_helper"

RSpec.describe Statements::StatementsQuery do
  describe "#statements" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns all statements" do
      statement = create(:statement)
      query = Statements::StatementsQuery.new(
        lead_provider:,
        params: {},
      )

      expect(query.statements).to eq([statement])
    end
  end
end
