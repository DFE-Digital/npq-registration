require "rails_helper"
require "api/version"

RSpec.feature "API documentation", type: :feature do
  API::Version.all.each do |version|
    scenario "viewing the #{version} API documentation" do
      visit "/api/docs/#{version}"

      expect(page).to have_css(".title", text: "NPQ Registration API")
      expect(page).to have_css(".version", text: version)
    end
  end
end
