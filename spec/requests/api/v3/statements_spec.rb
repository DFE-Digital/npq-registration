require "rails_helper"

RSpec.describe "Statements endpoint", type: "request" do
  describe "GET /api/v3/statements" do
    context "when authorized" do
      it "returns 200 - ok" do
        api_get("/api/v3/statements")

        expect(response.status).to eq 200
        expect(response.headers["Content-Type"]).to eql("application/json")
      end
    end

    context "when unauthorized" do
      it "returns 401 - unauthorized" do
        api_get("/api/v3/statements", token: "incorrect-token")

        expect(response.status).to eq 401
        expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
        expect(response.headers["Content-Type"]).to eql("application/json")
      end
    end
  end
end
