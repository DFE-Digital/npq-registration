require "rails_helper"

RSpec.describe NpqSeparation::ServiceNavigationComponent, type: :component do
  subject { render_inline component }

  let(:actor)     { nil }
  let(:component) { described_class.new(actor:, request:) }
  let(:request)   { instance_double(ActionDispatch::Request, path: "/", original_url: "https://www.example.com") }

  before { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(actor) }

  context "when not logged in" do
    it { is_expected.to have_text described_class::FULL_SERVICE_NAME }
    it { is_expected.not_to have_text described_class::ADMIN_SERVICE_NAME }
    it { is_expected.to have_css "a", count: 1 } # only the service name
  end

  context "when logged in as a user" do
    let(:actor) { build :user }

    it { is_expected.to have_text described_class::FULL_SERVICE_NAME }
    it { is_expected.to have_link "DfE Identity account" }
    it { is_expected.to have_link "Sign out" }
    it { is_expected.not_to have_text described_class::ADMIN_SERVICE_NAME }
    it { is_expected.not_to have_link "Dashboards" }

    context "with no applications" do
      it { is_expected.not_to have_link "NPQ account" }
    end

    context "with applications" do
      before { create :application, user: actor }

      it { is_expected.to have_link "NPQ account" }
    end
  end

  context "when logged in as an admin" do
    let(:actor) { build :admin }

    it { is_expected.to have_text described_class::ADMIN_SERVICE_NAME }
    it { is_expected.to have_link "Dashboards" }
    it { is_expected.to have_link "Sign out" }
    it { is_expected.not_to have_text described_class::FULL_SERVICE_NAME }
    it { is_expected.not_to have_link "DfE Identity account" }
  end
end
