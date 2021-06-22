require "rails_helper"

RSpec.describe SchoolsController do
  describe "#index" do
    before do
      create(:school, name: "heart", town: "London")
      create(:school, name: "health", town: "London")
      create(:school, :closed, name: "heat", town: "London")
      create(:school, name: "heal", town: "Manchester")
    end

    it "returns all possible matches" do
      get "/schools.json?location=london&name=he"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.size).to eql(2)
    end

    it "returns only needed data" do
      get "/schools.json?location=london&name=he"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.sample.keys).to eql(%w[urn name address])
      expect(parsed_response.sample["address"]).to be_a(String)
    end
  end
end
