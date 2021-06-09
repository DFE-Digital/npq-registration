require "rails_helper"

RSpec.describe CookiePreferencesController do
  describe "#create" do
    it "rejects cookies" do
      expect(cookies["consented-to-cookies"]).to be_blank
      post :create, params: { cookie_preferences: { consent: "reject", return_path: "/" } }
      expect(cookies["consented-to-cookies"]).to eql("reject")
    end

    it "accepts cookies" do
      expect(cookies["consented-to-cookies"]).to be_blank
      post :create, params: { cookie_preferences: { consent: "accept", return_path: "/" } }
      expect(cookies["consented-to-cookies"]).to eql("accept")
    end
  end
end
