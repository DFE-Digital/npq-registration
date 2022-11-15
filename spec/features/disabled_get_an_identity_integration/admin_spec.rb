require "rails_helper"

RSpec.feature "admin", type: :feature do
  include_context "Disable Get An Identity integration"

  let(:admin) { create(:admin) }

  around do |example|
    Capybara.current_driver = :rack_test
    previous_pagination = Pagy::DEFAULT[:items]
    Pagy::DEFAULT[:items] = 3
    example.run
    Pagy::DEFAULT[:items] = previous_pagination
    Capybara.current_driver = Capybara.default_driver
  end

  scenario "when logged in, it shows admin homepage" do
    visit "/admin"
    expect(page.current_path).to eql("/sign-in")

    page.fill_in "What’s your email address?", with: admin.email
    page.click_button "Sign in"
    expect(page.current_path).to eql("/session/sign-in-code")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"
    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    applications = create_list :application, 4

    page.click_link("Applications")
    expect(page.current_path).to eql("/admin/applications")

    applications[0..2].each do |app|
      expect(page).to have_content(app.user.email)
    end

    page.find("[aria-label=next]").click

    applications[3..].each do |app|
      expect(page).to have_content(app.user.email)
    end

    selected_application = applications.sample

    page.fill_in "Search by email", with: selected_application.user.email
    page.click_button "Search"

    expect(page.find_all("table tbody tr").size).to eql(1)

    click_link selected_application.user.email
    expect(page.current_path).to eql("/admin/applications/#{selected_application.id}")
  end
end
