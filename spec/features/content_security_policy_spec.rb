require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  scenario "script-src nonce on registration journey pages", :no_js do
    visit "/"
    expect(page.response_headers["content-security-policy-report-only"]).to match(/script-src .* 'nonce-.*/)
  end

  context "when showing error pages" do
    include_context "when errors are rendered"

    scenario "script-src nonce on not_found page", :no_js do
      visit "/thispagedoesnotexist"
      expect(page.response_headers["content-security-policy-report-only"]).to match(/script-src .* 'nonce-.*/)
    end
  end
end
