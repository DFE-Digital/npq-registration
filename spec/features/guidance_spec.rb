require "rails_helper"

RSpec.feature "Guidance", type: :feature do
  it "renders the index page" do
    visit "/api/guidance"

    expect(page).to have_content("Guidance")
  end

  describe "GET /api/guidance/get-started.md" do
    it "renders the .html page" do
      visit "/api/guidance/get-started.md"

      expect(page).not_to have_content("#Connect to the API")
      expect(page).to have_content("Connect to the API")
    end

    it "renders the navigation menu" do
      visit "/api/guidance/get-started.md"

      expect(page).to have_link("Connect to the API", href: "#connect-to-the-api")
    end
  end

  it "renders a nested markdown page" do
    # to be updated with a valid nested page
    visit "/api/guidance/nested/nested/test.md"

    expect(page).to have_content("This is a nested markdown page with .md extension")
  end
end
