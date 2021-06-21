require "rails_helper"

RSpec.feature "Cookies", type: :feature do
  scenario "view info about cookies" do
    visit "/"
    click_link("View cookies")

    expect(page).to be_axe_clean
    expect(page).to have_content("Cookies are small files saved on your phone, tablet or computer when you visit a website.")
  end

  scenario "when rejecting cookies" do
    visit "/"
    expect(page).to have_content("We use some essential cookies to make this service work.")
    click_button("Reject additional cookies")

    expect(page).to be_axe_clean
    expect(page).to have_content("You’ve rejected additional cookies")
    click_button("Hide this message")

    expect(page).to be_axe_clean
    expect(page).not_to have_content("You’ve rejected additional cookies")
  end

  scenario "when accepting cookies" do
    visit "/"

    expect(page).to be_axe_clean
    expect(page).to have_content("We use some essential cookies to make this service work.")
    click_button("Accept additional cookies")

    expect(page).to be_axe_clean
    expect(page).to have_content("You’ve accepted additional cookies")
    click_button("Hide this message")

    expect(page).to be_axe_clean
    expect(page).not_to have_content("You’ve accepted additional cookies")
  end
end
