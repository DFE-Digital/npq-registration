require "rails_helper"

RSpec.feature "admin", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include_context "Stub Get An Identity Omniauth Responses"

  let(:admin) { create(:admin) }
  let(:super_admin) { create(:super_admin) }
  let(:separation_admin_link_text) { "Separation Admin" }
  let(:feature_flags_link_text) { "Feature flags" }

  before do
    create(:cohort, :current)
  end

  scenario "regular admins cannot see links that super admins can" do
    sign_in_as_admin
    click_link(separation_admin_link_text)
    expect(page).not_to have_link(feature_flags_link_text)
  end

  scenario "super admins can see links that regular admins can't" do
    sign_in_as_super_admin
    click_link(separation_admin_link_text)
    expect(page).to have_link(feature_flags_link_text, href: "/npq-separation/admin/features")
  end
end
