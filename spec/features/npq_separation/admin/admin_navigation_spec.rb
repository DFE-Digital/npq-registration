require "rails_helper"

RSpec.feature "admin", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include_context "Stub Get An Identity Omniauth Responses"

  let(:admin) { create(:admin) }

  scenario "regular admins cannot see links that super admins can" do
    create(:cohort, :current)
    sign_in_as_admin
    visit "/npq-separation/admin"
    click_link("Separation Admin")
    expect(page).not_to have_link("Feature flags", href: "/npq-separation/admin/features")
  end
end
