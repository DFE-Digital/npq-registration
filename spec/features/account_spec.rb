require "rails_helper"

RSpec.feature "Account", type: :feature do
  scenario "when not logged in, it redirects to sign in" do
    visit "/account"
    expect(page.current_path).to eql("/sign-in")
  end
end
