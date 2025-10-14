# frozen_string_literal: true

require "rails_helper"

RSpec.describe Banners::MaintenanceComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new }

  before do
    Flipper.enable(Feature::MAINTENANCE_BANNER)
  end

  subject do
    render_inline(component)
    page
  end

  it { is_expected.to have_css(".govuk-width-container") }
  it { is_expected.to have_css("h2", text: "Important") }
  it { is_expected.to have_css(".govuk-notification-banner__heading", text: Banners::MaintenanceComponent::MAINTENANCE_TEXT) }
  it { is_expected.to have_link("Dismiss", href: maintenance_banner_dismiss_path) }

  describe "#render?" do
    subject { component }

    it { is_expected.to be_render }

    context "when the maintenance banner feature flag is not active" do
      before { Flipper.disable(Feature::MAINTENANCE_BANNER) }

      it { is_expected.not_to be_render }
    end
  end
end
