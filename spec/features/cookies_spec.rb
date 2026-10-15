require "rails_helper"

RSpec.feature "Cookies", type: :feature do
  scenario "view info about cookies" do
    visit "/"
    click_link("View cookies")

    expect(page).to be_accessible
    expect(page).to have_content("Cookies are small files saved on your phone, tablet or computer when you visit a website.")
  end

  scenario "when rejecting cookies" do
    visit "/"
    expect(page).to have_content("We use some essential cookies to make this service work.")
    click_button("Reject additional cookies")

    expect(page).to be_accessible
    expect(page).to have_content("You’ve rejected analytics cookies")
    click_button("Hide this message")

    expect(page).to be_accessible
    expect(page).not_to have_content("You’ve rejected additional cookies")
  end

  scenario "when accepting cookies" do
    visit "/"

    expect(page).to be_accessible
    expect(page).to have_content("We use some essential cookies to make this service work.")
    click_button("Accept additional cookies")

    expect(page).to be_accessible
    expect(page).to have_content("You’ve accepted analytics cookies")
    click_button("Hide this message")

    expect(page).to be_accessible
    expect(page).not_to have_content("You’ve accepted additional cookies")
  end

  scenario "when saving the choice fails" do
    page.driver.browser.network.intercept
    page.driver.browser.on(:request) do |request|
      if request.match?(%r{/cookie_preferences})
        request.respond(responseCode: 500, body: "")
      else
        request.continue
      end
    end

    visit "/"
    expect(page).not_to have_content("Sorry, there is a problem with the service. Try again later.")
    click_button("Reject additional cookies")

    expect(page).to have_current_path("/")
    expect(page).to have_content("Sorry, there is a problem with the service. Try again later.")
    expect(page).to have_button("Reject additional cookies")
    expect(page.driver.cookies["consented-to-cookies"]).to be_nil
  end
end
