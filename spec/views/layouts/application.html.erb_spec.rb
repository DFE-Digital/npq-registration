require "rails_helper"

RSpec.describe "layouts/application.html.erb", type: :view do
  subject { Capybara.string(render) }

  let(:service_name) { "Register for a national professional qualification" }
  let(:onelogin_account_link_text) { "OneLogin account" }
  let(:dfe_identity_account_link_text) { "DfE Identity account" }
  let(:npq_account_link_text) { "NPQ account" }
  let(:sign_out_link_text) { "Sign out" }
  let(:one_login_header_selector) { "[data-module='one-login-header']" }

  let(:user) { nil }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(request).to receive(:original_url).and_return("http://example.com")
  end

  describe "service navigation" do
    context "when not logged in" do
      it { is_expected.to have_css(".govuk-service-navigation__container", text: service_name) }
      it { is_expected.not_to have_css(one_login_header_selector) }
      it { is_expected.not_to have_link(onelogin_account_link_text) }
      it { is_expected.not_to have_link(dfe_identity_account_link_text) }
      it { is_expected.not_to have_link(npq_account_link_text) }
      it { is_expected.not_to have_link(sign_out_link_text) }
    end

    context "when logged in via One Login (teacher_auth)" do
      let(:user) { build(:user, :with_teacher_auth) }

      it { is_expected.to have_css(".govuk-service-navigation__container", text: service_name) }
      it { is_expected.to have_css(one_login_header_selector) }

      it "renders the GOV.UK One Login link and a Sign out link in the One Login header" do
        within(one_login_header_selector) do
          expect(subject).to have_link("GOV.UK One Login")
          expect(subject).to have_link(sign_out_link_text, href: sign_out_user_path)
        end
      end

      it "does not duplicate the account or Sign out links in the service navigation" do
        within(".govuk-service-navigation__container") do
          expect(subject).not_to have_link(onelogin_account_link_text)
          expect(subject).not_to have_link(sign_out_link_text)
        end
      end

      context "with no applications" do
        it { is_expected.not_to have_link(npq_account_link_text) }
      end

      context "with applications" do
        before { create(:application, user:) }

        it { is_expected.to have_link(npq_account_link_text) }
      end
    end

    context "when logged in via Get an Identity (tra_openid_connect)" do
      let(:user) { build(:user, :with_get_an_identity_id) }

      it { is_expected.to have_css(".govuk-service-navigation__container", text: service_name) }
      it { is_expected.not_to have_css(one_login_header_selector) }
      it { is_expected.to have_link(dfe_identity_account_link_text) }
      it { is_expected.to have_link(sign_out_link_text, href: sign_out_user_path) }

      context "with no applications" do
        it { is_expected.not_to have_link(npq_account_link_text) }
      end

      context "with applications" do
        before { create(:application, user:) }

        it { is_expected.to have_link(npq_account_link_text) }
      end
    end
  end
end
