require "rails_helper"

RSpec.describe IdentityAccountHelper, type: :helper do
  include Helpers::JourneyHelper

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
