require "rails_helper"

RSpec.describe IdentityAccountHelper, type: :helper do
  include Helpers::JourneyHelper

  before { stub_env_variables_for_gai }

  describe "#link_to_identity_account" do
    let(:redirect_uri) { "https://redirect.uri" }

    subject(:link) { link_to_identity_account(redirect_uri) }

    it "is built with the TRA domain" do
      expect(link).to match(ENV["TRA_OIDC_DOMAIN"])
    end
  end
end
