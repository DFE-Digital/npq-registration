require "rails_helper"

RSpec.feature "Guidance", type: :feature do
  describe "Back link navigation" do
    it "renders a working back link on non-index guidance pages" do
      visit "/api/guidance"

      expect(page).not_to have_link("Back")

      within("nav") { click_on "Get started" }

      expect(page).to have_link("Back", href: %r{/api/guidance})

      click_on "Back"

      expect(page).to have_current_path("/api/guidance", ignore_query: true)
    end
  end

  describe "GET /api/guidance" do
    it "renders the index page" do
      visit "/api/guidance"

      expect(page).to have_content("Guidance")
    end

    it "renders the call to action button" do
      visit "/api/guidance"

      expect(page).to have_link("Get started", href: "/api/guidance/get-started")
    end
  end

  describe "GET /api/guidance/get-started" do
    it "renders the .html page" do
      visit "/api/guidance/get-started"

      expect(page).not_to have_content("#Connect to the API")
      expect(page).to have_content("Connect to the API")
    end
  end

  describe "GET /api/guidance/test-environments" do
    it "renders the .html page" do
      visit "/api/guidance/test-environments"

      expect(page).not_to have_content("#What are the test environments")
      expect(page).to have_content("The test environments are used to test.")
    end
  end

  describe "GET /api/guidance/release-notes" do
    it "renders the .html page" do
      visit "/api/guidance/release-notes"

      expect(page).not_to have_content("#What's new'")
      expect(page).to have_content("What's new")
    end
  end

  it "renders a nested markdown page" do
    # to be updated with the first nested page
    visit "/api/guidance/nested/nested/test"

    expect(page).to have_content("This is a nested markdown page")
  end
end
