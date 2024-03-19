require "rails_helper"

RSpec.feature "Guidance", type: :feature do
  it "renders the index page" do
    visit "/api/guidance"

    expect(page).to have_content("Guidance")
  end

  it "renders a markdown page with .md extension" do
    visit "/api/guidance/test.md" # to be updated with a valid page

    expect(page).to have_content("This is a markdown page with .md extension")
  end
end
