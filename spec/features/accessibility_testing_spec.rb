require "rails_helper"

RSpec.feature "Check accessibility testing works", type: :feature do
  scenario "testing pages for wcag2a" do
    visit "/wcag2a"

    expect(page).not_to be_axe_clean.according_to :wcag2a # expecting failures for empty h1 and img with no alt text
    expect(page).to be_axe_clean.according_to :wcag22aa
  end

  scenario "testing pages for wcag22aa" do
    visit "/wcag22aa"

    expect(page).not_to be_axe_clean.according_to :wcag2a # expecting failures for empty h1 and img with no alt text
    expect(page).not_to be_axe_clean.according_to :wcag22aa # expecting failure for target-size
  end
end
