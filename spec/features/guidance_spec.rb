require "rails_helper"

RSpec.feature "Guidance", type: :feature do
  it "renders the index page" do
    visit "/api/guidance"

    expect(page).to have_content("Guidance")
  end

  it "renders a markdown page with .md extension" do
    # to be updated with a valid guidance page
    visit "/api/guidance/test.md"

    expect(page).to have_content("This is a markdown page with .md extension")
  end

  it "renders a nested markdown page" do
    # to be updated with a valid nested page
    visit "/api/guidance/nested/nested/test.md"

    expect(page).to have_content("This is a nested markdown page with .md extension")
  end
end
