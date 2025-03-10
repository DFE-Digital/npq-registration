require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  scenario "script-src nonce on registration journey pages", :no_js do
    visit "/"
    expect(page.response_headers["content-security-policy-report-only"]).to match(/script-src .* 'nonce-.*/)
  end

  context "when showing error pages" do
    before do
      method = Rails.application.method(:env_config)
      allow(Rails.application).to receive(:env_config).with(no_args) do
        method.call.merge(
          "action_dispatch.show_exceptions" => :all,
          "action_dispatch.show_detailed_exceptions" => false,
          "consider_all_requests_local" => false,
        )
      end
    end

    scenario "script-src nonce on not_found page", :no_js do
      visit "/thispagedoesnotexist"
      expect(page.response_headers["content-security-policy-report-only"]).to match(/script-src .* 'nonce-.*/)
    end
  end
end
