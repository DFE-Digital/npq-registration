require "rails_helper"

RSpec.feature "admin", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include_context "Stub Get An Identity Omniauth Responses"

  let(:super_admin) { create(:super_admin) }
  let(:admin) { create(:admin) }

  around do |example|
    previous_pagination = Pagy::DEFAULT[:limit]
    Pagy::DEFAULT[:limit] = 3
    example.run
    Pagy::DEFAULT[:limit] = previous_pagination
  end

  scenario "when not logged in, admin interface is inaccessible" do
    [
      admin_path,
      admin_applications_path,
      admin_unsynced_applications_path,
      admin_unsynced_users_path,
      admin_schools_path,
    ].each do |href|
      visit href
      expect(page).to have_current_path(sign_in_path)
    end
  end

  scenario "when logged in as a regular admin, it allows access to the admin homepage" do
    sign_in_as_admin

    # Check the links are present
    {
      "Dashboard" => admin_path,
      "Applications" => admin_applications_path,
      "Unsynced applications" => admin_unsynced_applications_path,
      "Unsynced users" => admin_unsynced_users_path,
      "Schools" => admin_schools_path,
    }.each do |text, href|
      # Check the links are present
      expect(page).to have_link(text, href:)
    end
    expect(page).not_to have_link("Admin Users", href: "/admin/admins")
  end

  scenario "when logged in as a regular admin, it allows access to the dashboard" do
    create_list :application, 4

    visit "/admin"

    sign_in_as_admin

    expect(page).to have_link("Dashboard", href: admin_path)
    page.click_link("Dashboard")
    expect(page).to have_current_path(admin_path)
  end

  scenario "when logged in as a regular admin, it allows access to the applications interfaces" do
    create_list(:application, 4, ecf_id: nil)

    sign_in_as_admin

    page.click_link("Legacy Admin")
    expect(page).to have_current_path("/admin")

    expect(page).to have_link("Applications", href: admin_applications_path)
    page.click_link("Applications")
    expect(page).to have_current_path(admin_applications_path)

    applications = Application.all.order(id: :asc)

    # Test application pagination
    applications[0..2].each do |app|
      expect(page).to have_content(app.user.email)
    end

    page.find("[rel=next]").click

    applications[3..].each do |app|
      expect(page).to have_content(app.user.email)
    end

    # Test application search and show page
    selected_application = applications.sample

    successful_sync_log = selected_application.ecf_sync_request_logs.create!(
      status: :success,
      sync_type: :application_creation,
      created_at: 15.days.ago,
    )

    failed_sync_log = selected_application.ecf_sync_request_logs.create!(
      status: :failed,
      sync_type: :application_creation,
      error_messages: %w[foobar],
      created_at: 16.days.ago,
    )

    page.fill_in "Search by email", with: selected_application.user.email
    page.click_button "Search"

    expect(page.find_all("table tbody tr").size).to be(1)

    click_link selected_application.user.email
    expect(page).to have_current_path(admin_application_path(id: selected_application.id))

    expect(page).to have_link("ECF Sync Log", href: "#ecf-sync-log")

    click_link "ECF Sync Log"
    within "#log-row-#{successful_sync_log.id}" do
      expect(page.text).to eq [
        "Application Creation",
        successful_sync_log.created_at.to_formatted_s(:govuk_short),
        "Success",
        "-",
      ].join(" ")
    end

    within "#log-row-#{failed_sync_log.id}" do
      expect(page.text).to eq [
        "Application Creation",
        failed_sync_log.created_at.to_formatted_s(:govuk_short),
        "Failed",
        failed_sync_log.error_messages.join(", "),
      ].join(" ")
    end

    expect(page).to have_link("Back", href: admin_applications_url(q: selected_application.user.email))
  end

  scenario "when logged in as a regular admin, it allows access to the schools interface" do
    create_list :application, 4

    sign_in_as_admin

    expect(page).to have_link("Schools", href: admin_schools_path)
    page.click_link("Schools")
    expect(page).to have_current_path(admin_schools_path)
  end

  scenario "when logged in as a regular admin, admin can log out" do
    sign_in_as_admin

    expect(page).to have_link("Sign out", href: "/sign-out")

    click_link "Sign out"

    expect(page).to have_current_path(root_path)
    expect(page).not_to have_link("Sign out")
  end

  scenario "when logged in it shows links to legacy and npq-separation admin" do
    sign_in_as_admin

    expect(page).to have_link("Legacy Admin", href: admin_path)
    expect(page).to have_link("Separation Admin", href: npq_separation_admin_path)
  end
end
