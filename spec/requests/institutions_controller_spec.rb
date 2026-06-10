require "rails_helper"

RSpec.describe InstitutionsController do
  describe "#index" do
    before do
      create(:school, name: "heart", town: "London")
      create(:school, name: "health", town: "London")
      create(:school, :closed, name: "heat", town: "London")
      create(:school, name: "heal", town: "Manchester", postcode: "EC1N 2TD", postcode_without_spaces: "EC1N2TD")
      create(:school, name: "St Mary's", town: "Manchester")

      create(:local_authority, name: "heap", town: "London")
    end

    it "returns all possible matches" do
      get "/institutions.json?location=&name=hea"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.size).to be(4)
    end

    it "returns only needed data" do
      get "/institutions.json?location=&name=hea"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.sample.keys).to eql(%w[identifier urn name address])
      expect(parsed_response.sample["address"]).to be_a(String)
    end

    it "includes the urn for schools and nil for local authorities" do
      get "/institutions.json?location=&name=hea"

      parsed_response = JSON.parse(response.body)

      school_result = parsed_response.find { |i| i["identifier"].start_with?("School-") }
      local_authority_result = parsed_response.find { |i| i["identifier"].start_with?("LocalAuthority-") }

      expect(school_result["urn"]).to be_present
      expect(local_authority_result["urn"]).to be_nil
    end

    it "searches using a postcode" do
      get "/institutions.json?location=&name=ec1n2td"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response.sample.keys).to eql(%w[identifier urn name address])
      expect(parsed_response.sample["address"]).to be_a(String)
    end
  end
end
