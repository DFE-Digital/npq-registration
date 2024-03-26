require "rails_helper"

RSpec.feature "Guidance", type: :feature do
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

  describe "GET /api/guidance/what-you-can-do-in-the-api.md" do
    it "renders the .html page" do
      visit "/api/guidance/what-you-can-do-in-the-api"

      expect(page).not_to have_content("#What you can do in the API")
      expect(page).to have_content("What you can do in the API")
    end
  end

  describe "GET /api/guidance/definitions" do
    it "renders the .html page" do
      visit "/api/guidance/definitions"

      expect(page).not_to have_content("#Definitions")
      expect(page).to have_content("Definitions")
    end
  end

  describe "GET /api/guidance/api-latest-version" do
    it "renders the .html page" do
      visit "/api/guidance/api-latest-version"

      expect(page).not_to have_content("#API latest version")
      expect(page).to have_content("API latest version")
    end
  end

  describe "GET /api/guidance/test-environment" do
    it "renders the .html page" do
      visit "/api/guidance/test-environment"

      expect(page).not_to have_content("#Test environment")
      expect(page).to have_content("Test environment")
    end
  end

  it "renders a nested markdown page" do
    # to be updated with the first nested page
    visit "/api/guidance/nested/nested/test"

    expect(page).to have_content("This is a nested markdown page")
  end
end