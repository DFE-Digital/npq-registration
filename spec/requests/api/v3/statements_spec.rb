require "rails_helper"

RSpec.describe "Statements endpoint", type: "request" do
  let(:lead_provider) { create(:lead_provider) }
  let(:token) { APIToken.create_with_random_token!(lead_provider:) }
  let(:parsed_response) { JSON.parse(response.body) }

  describe "GET /api/v3/statements" do
    context "when authorized" do
      before do
        default_headers[:Authorization] = "Bearer #{token}"
      end

      it "returns 200 - ok" do
        get("/api/v3/statements")

        expect(response.status).to eq 200
        expect(response.headers["Content-Type"]).to include("application/json")
      end
    end

    context "when unauthorized" do
      let(:token) { "incorrect-token" }

      it "returns 401 - unauthorized" do
        get("/api/v3/statements")

        expect(response.status).to eq 401
        expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
        expect(response.headers["Content-Type"]).to include("application/json")
      end
    end
  end
end
