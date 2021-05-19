require "rails_helper"

RSpec.describe MonitoringController do
  describe "#healthcheck" do
    it "returns OK response" do
      get :healthcheck, format: :json
      expect(response).to be_successful

      hash = JSON.parse(response.body)
      expect(hash["status"]).to eql("OK")
    end
  end
end
