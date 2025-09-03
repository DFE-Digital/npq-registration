# frozen_string_literal: true

require "rails_helper"

RSpec.describe "robots.txt" do
  subject { response }

  let(:request) { get "/robots.txt" }

  context "when the environment is not production" do
    before { request }

    it "disallows everything" do
      expect(response.body).to eq <<~TXT
        User-agent: *
        Disallow: /
      TXT
    end
  end

  context "when the environment is production" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      request
    end

    it "disallows specific paths, including admin paths" do
      expect(response.body).to eq <<~TXT
        User-agent: *
        Disallow: /account
        Disallow: /admin
        Disallow: /npq-separation/admin
        Disallow: /registration
        Disallow: /session
        Disallow: /sign-in
        Disallow: /sign-out
      TXT
    end
  end

  context "when requesting other formats" do
    let(:request) { get "/robots.json" }

    before { request }

    it "returns a 404" do
      expect(response).to have_http_status(:not_found)
    end
  end
end
