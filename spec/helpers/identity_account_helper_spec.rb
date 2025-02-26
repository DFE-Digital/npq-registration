require "rails_helper"

RSpec.describe IdentityAccountHelper, type: :helper do
  include Helpers::JourneyHelper

  before { stub_env_variables_for_gai }

  describe "#link_to_identity_account" do
    subject(:link) { helper.link_to_identity_account(redirect_uri) }

    let(:redirect_uri) { "https://redirect.uri?param=value" }

    it "is built with the TRA domain" do
      expect(link).to match("https://tra-domain.com")
    end

    it "includes the client_id query parameter" do
      expect(link).to match("client_id=register-for-npq")
    end

    it "includes the URL encoded redirect_id query parameter" do
      # CGI::escape('https://redirect.uri?param=value')
      url_encoded = "https%3A%2F%2Fredirect.uri%3Fparam%3Dvalue"

      expect(link).to match("redirect_uri=#{url_encoded}")
    end

    it "includes the URL encoded for the sign_out parameter" do
      # CGI::escape('https://redirect.uri/sign-out')
      url_encoded = "https%3A%2F%2Fredirect.uri%2Fsign-out"

      expect(link).to match("sign_out_uri=#{url_encoded}")
    end
  end

  describe "#identity_link_uri" do
    let(:fake_account_link) do
      instance_double(IdentityAccountHelper::IdentityAccountLink, build: true)
    end

    before do
      allow(IdentityAccountHelper::IdentityAccountLink).to(receive(:new).and_return(fake_account_link))
    end

    it "passes the provided uri into IdentityAccountLink" do
      uri = "https://example.com/123"

      identity_link_uri(uri)

      expect(IdentityAccountHelper::IdentityAccountLink).to(have_received(:new).with(uri))
      expect(fake_account_link).to have_received(:build)
    end
  end
end
