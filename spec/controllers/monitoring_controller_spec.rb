require "rails_helper"

RSpec.describe MonitoringController do
  describe "#healthcheck" do
    it "returns OK response" do
      get :healthcheck, format: :json
      expect(response).to be_successful
      expect(JSON.parse(response.body)).to include("git_commit_sha", "database")
    end
  end
end
