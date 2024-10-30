# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Maintenance banner" do
  before do
    Flipper.enable(Feature::MAINTENANCE_BANNER)
    stub_const("Banners::MaintenanceComponent::MAINTENANCE_WINDOW", 1.day.ago..1.day.from_now)
  end

  scenario "viewing the root path" do
    visit root_path
    expect(page).to have_text(/This service will be unavailable from/)
  end

  scenario "viewing an API guidance path" do
    visit api_guidance_path
    expect(page).to have_text(/This service will be unavailable from/)
  end

  scenario "viewing an API docs path" do
    visit api_documentation_path(version: "v1")
    expect(page).to have_text(/This service will be unavailable from/)
  end

  context "when disabled" do
    before { Flipper.disable(Feature::MAINTENANCE_BANNER) }

    scenario "viewing the root path" do
      visit root_path
      expect(page).not_to have_text(/This service will be unavailable from/)
    end

    scenario "viewing an API guidance path" do
      visit api_guidance_path
      expect(page).not_to have_text(/This service will be unavailable from/)
    end

    scenario "viewing the API docs" do
      visit api_documentation_path(version: "v1")
      expect(page).not_to have_text(/This service will be unavailable from/)
    end
  end
end
