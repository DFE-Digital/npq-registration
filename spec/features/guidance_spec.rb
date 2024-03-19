require "rails_helper"

RSpec.feature "Guidance", type: :feature do
  it "renders the index page" do
    visit "/api/guidance"

    expect(page).to have_content("Guidance")
  end
end
