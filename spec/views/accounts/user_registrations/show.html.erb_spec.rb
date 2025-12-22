require "rails_helper"

RSpec.describe "accounts/user_registrations/show.html.erb", type: :view do
  include CourseHelper

  subject { Capybara.string(render) }

  let(:user) { create(:user) }
  let(:application) { create(:application, user:) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    assign(:application, application)
    allow(Feature).to receive(:registration_closed?).and_return(false)
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with("provider_pending_status").and_return("")
    allow(view).to receive_messages(application_course_start_date: "autumn 2025", pending?: true, accepted?: false, rejected?: false, account_path: "/account", change_registration_closed_path: "/change-registration-closed", registration_wizard_show_url: "/registration-wizard", link_to_identity_account: "")
  end

  it { is_expected.to have_css(".govuk-caption-m", text: "Submitted #{application.created_at.to_date.to_fs(:govuk_short)}") }
  it { is_expected.to have_css(".govuk-body", text: "Application ID: #{application.ecf_id}") }

  describe "page title" do
    it "sets the page title" do
      render
      expect(view.content_for(:title)).to eq("Your registration details")
    end
  end

  describe "success notification banner" do
    context "when success param is true" do
      before do
        allow(view).to receive(:params).and_return({ success: "true" })
      end

      it { is_expected.to have_css(".govuk-notification-banner--success") }
      it { is_expected.to have_css(".govuk-notification-banner__heading", text: "Registration successfully submitted") }
    end

    context "when success param is not present" do
      it { is_expected.not_to have_css(".govuk-notification-banner--success") }
    end
  end

  describe "back link" do
    context "when user has only one application" do
      it { is_expected.not_to have_link("Back to your registrations") }
    end

    context "when user has multiple applications" do
      before { create(:application, user:) }

      it "shows back link in before_content" do
        render
        expect(view.content_for(:before_content)).to include("Back to your registrations")
      end
    end
  end

  describe "heading" do
    context "when user has only one application" do
      it { is_expected.to have_css("h1.govuk-heading-xl", text: I18n.t("accounts.show.title")) }
    end

    context "when user has multiple applications" do
      before { create(:application, user:) }

      it { is_expected.to have_css("h1.govuk-heading-xl", text: "Your #{title_embedded_course_name(application.course)} registration") }
    end
  end

  describe "partials" do
    it "renders course details partial" do
      render
      expect(rendered).to include("Course details")
    end

    it "renders funding details partial" do
      render
      expect(rendered).to include("Funding details")
    end

    it "renders personal details partial" do
      render
      expect(rendered).to include("Personal details")
    end

    it "renders work details partial" do
      render
      expect(rendered).to include("Work details")
    end
  end

  describe "register for an NPQ section" do
    context "when registration is enabled" do
      before do
        allow(Feature).to receive(:registration_enabled?).and_return(true)
        allow(view).to receive(:render).with(partial: "registration_wizard/shared/register_for_an_npq").and_return("")
      end

      it "renders the register for an NPQ partial" do
        render
        expect(view).to have_received(:render).with(partial: "registration_wizard/shared/register_for_an_npq")
      end
    end

    context "when registration is disabled" do
      before do
        allow(Feature).to receive(:registration_enabled?).and_return(false)
      end

      it "does not render the register for an NPQ partial" do
        render
        expect(rendered).not_to include("register_for_an_npq")
      end
    end
  end
end
