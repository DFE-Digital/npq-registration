require "rails_helper"

RSpec.describe SchoolsController do
  describe "#index" do
    before do
      create(:school, name: "heart", town: "London")
      create(:school, name: "health", town: "London")
      create(:school, :closed, name: "heat", town: "London")
      create(:school, name: "heal", town: "Manchester", postcode: "EC1N 2TD", postcode_without_spaces: "EC1N2TD")
    end

    it "returns all possible matches" do
      get "/schools.json?location=london&name=hea"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.size).to eql(2)
    end

    it "returns only needed data" do
      get "/schools.json?location=london&name=hea"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.sample.keys).to eql(%w[urn name address])
      expect(parsed_response.sample["address"]).to be_a(String)
    end

    it "returns postcode when whitespace is removed" do
      get "/schools.json?location=ec1n2td&name=hea"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.sample.keys).to eql(%w[urn name address])
      expect(parsed_response.sample["address"]).to be_a(String)
    end
  end
end
