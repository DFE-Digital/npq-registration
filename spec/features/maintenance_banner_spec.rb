# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Maintenance banner", :no_js do
  before do
    Flipper.enable(Feature::MAINTENANCE_BANNER)
  end

  scenario "viewing the root path" do
    visit root_path
    expect(page).to have_text(Banners::MaintenanceComponent::MAINTENANCE_TEXT)
  end

  scenario "viewing an API guidance path" do
    visit api_guidance_path
    expect(page).to have_text(Banners::MaintenanceComponent::MAINTENANCE_TEXT)
  end

  scenario "viewing an API docs path" do
    visit api_documentation_path(version: "v3")
    expect(page).to have_text(Banners::MaintenanceComponent::MAINTENANCE_TEXT)
  end

  context "when disabled" do
    before { Flipper.disable(Feature::MAINTENANCE_BANNER) }

    scenario "viewing the root path" do
      visit root_path
      expect(page).not_to have_text(Banners::MaintenanceComponent::MAINTENANCE_TEXT)
    end

    scenario "viewing an API guidance path" do
      visit api_guidance_path
      expect(page).not_to have_text(Banners::MaintenanceComponent::MAINTENANCE_TEXT)
    end

    scenario "viewing the API docs" do
      visit api_documentation_path(version: "v3")
      expect(page).not_to have_text(Banners::MaintenanceComponent::MAINTENANCE_TEXT)
    end
  end
end
