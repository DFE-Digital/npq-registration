require "rails_helper"

RSpec.describe Statements::Query do
  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:) }

  describe "#statements" do
    it "returns all statements for a Lead Provider" do
      query = Statements::Query.new(lead_provider:)

      expect(query.statements).to eq([statement])
    end

    it "does not return statements for other Lead Providers" do
      other_lead_provider = create(:lead_provider)
      create(:statement, lead_provider: other_lead_provider)

      query = Statements::Query.new(lead_provider:)

      expect(query.statements).to eq([])
    end
  end

  describe "#statement" do
    it "returns the statement for a Lead Provider" do
      query = Statements::Query.new(lead_provider:)

      expect(query.statement(id: statement.id)).to eq(statement)
    end

    it "raises an error if the statement does not exist" do
      query = Statements::Query.new(lead_provider:)

      expect { query.statement(id: 0) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the statement belong to other Lead Provider" do
      other_lead_provider = create(:lead_provider)
      other_statement = create(:statement, lead_provider: other_lead_provider)

      query = Statements::Query.new(lead_provider:)

      expect { query.statement(id: other_statement.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
