require "rails_helper"

RSpec.feature "Sessions: integration with GAI", type: :feature do
  include Helpers::JourneyHelper

  include_context "Stub Get An Identity Omniauth Responses"

  before do
    allow(User).to receive(:find_by).and_return(FactoryBot.create(:user))
  end

  scenario "GAI header links are only visible for logged-in users" do
    visit "/"

    expect(page).to have_link("Sign out", href: /\/sign-out/)
    expect(page).to have_link("DfE Identity account", href: /\/account\?client_id=register-for-npq&redirect_uri=[^&]+&sign_out_uri=[^&]+/)
  end
end
