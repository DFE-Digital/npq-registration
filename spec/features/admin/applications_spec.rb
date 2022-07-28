require "rails_helper"

RSpec.feature "administering applications", type: :feature do
  let(:admin) { create(:admin) }

  around do |example|
    Capybara.current_driver = :rack_test
    previous_pagination = Pagy::DEFAULT[:items]
    Pagy::DEFAULT[:items] = 3
    example.run
    Pagy::DEFAULT[:items] = previous_pagination
    Capybara.current_driver = Capybara.default_driver
  end

  include_context "sign in as admin"

  scenario "viewing application records" do
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
