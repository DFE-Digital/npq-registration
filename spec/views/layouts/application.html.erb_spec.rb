require "rails_helper"

RSpec.describe "layouts/application.html.erb", type: :view do
  subject { Capybara.string(render) }

  let(:service_name) { "Register for a national professional qualification" }
  let(:dfe_identity_account_link_text) { "DfE Identity account" }
  let(:npq_account_link_text) { "NPQ account" }
  let(:sign_out_link_text) { "Sign out" }

  let(:user) { nil }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(request).to receive(:original_url).and_return("http://example.com")
  end

  describe "service navigation" do
    context "when not logged in" do
      it { is_expected.to have_css(".govuk-service-navigation__container", text: service_name) }
      it { is_expected.not_to have_link(dfe_identity_account_link_text) }
      it { is_expected.not_to have_link(npq_account_link_text) }
      it { is_expected.not_to have_link(sign_out_link_text) }
    end

    context "when logged in as a user" do
      let(:user) { build(:user) }

      context "with no applications" do
        it { is_expected.to have_css(".govuk-service-navigation__container", text: service_name) }
        it { is_expected.to have_link(dfe_identity_account_link_text) }
        it { is_expected.not_to have_link(npq_account_link_text) }
        it { is_expected.to have_link(sign_out_link_text) }
      end

      context "with applications" do
        before { create(:application, user:) }

        it { is_expected.to have_css(".govuk-service-navigation__container", text: service_name) }
        it { is_expected.to have_link(dfe_identity_account_link_text) }
        it { is_expected.to have_link(npq_account_link_text) }
        it { is_expected.to have_link(sign_out_link_text) }
      end
    end
  end
end
