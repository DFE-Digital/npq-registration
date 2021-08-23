require "rails_helper"

RSpec.describe InstitutionsController do
  describe "#index" do
    before do
      create(:school, name: "heart", town: "London")
      create(:school, name: "health", town: "London")
      create(:school, :closed, name: "heat", town: "London")
      create(:school, name: "heal", town: "Manchester", postcode: "EC1N 2TD", postcode_without_spaces: "EC1N2TD")

      create(:local_authority, name: "heap", town: "London")
    end

    it "returns all possible matches" do
      get "/institutions.json?location=london&name=hea"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.size).to eql(3)
    end

    it "returns only needed data" do
      get "/institutions.json?location=london&name=hea"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.sample.keys).to eql(%w[urn ukprn name address])
      expect(parsed_response.sample["address"]).to be_a(String)
    end

    it "returns postcode when whitespace is removed" do
      get "/institutions.json?location=ec1n2td&name=hea"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.sample.keys).to eql(%w[urn ukprn name address])
      expect(parsed_response.sample["address"]).to be_a(String)
    end
  end
end
