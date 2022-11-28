require "rails_helper"

RSpec.feature "admin", type: :feature do
  include_context "Enable Get An Identity integration"

  let(:admin) { create(:admin) }

  around do |example|
    Capybara.current_driver = :rack_test
    previous_pagination = Pagy::DEFAULT[:items]
    Pagy::DEFAULT[:items] = 3
    example.run
    Pagy::DEFAULT[:items] = previous_pagination
    Capybara.current_driver = Capybara.default_driver
  end

  def sign_in_as_admin
    expect(page.current_path).to eql("/sign-in")

    page.fill_in "What’s your email address?", with: admin.email
    page.click_button "Sign in"
    expect(page.current_path).to eql("/session/sign-in-code")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"
  end

  scenario "when logged in, it shows admin homepage" do
    visit "/admin"

    sign_in_as_admin

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

  scenario "viewing the unsynced applications" do
    visit "/admin"

    sign_in_as_admin

    expect(page.current_path).to eql("/account")
    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    # when there are no unsynced records
    page.click_link("Unsynced applications")
    expect(page).to have_content("All applications have been successfuly linked with an ECF user.")

    # when there are some unsynced records
    applications = create_list(:application, 3)
    create_list(:application, 1, :with_ecf_id)

    page.click_link("Unsynced applications")

    applications.each do |app|
      expect(page).to have_content(app.user.email)
    end

    expect(page.find_all("table tbody tr").size).to eql(applications.size)

    # viewing an unsynced record
    page.click_link applications.first.user.email
    expect(page.current_path).to eql("/admin/unsynced-applications/#{applications.first.id}")

    expect(page).to have_content(applications.first.user.full_name)
  end
end
