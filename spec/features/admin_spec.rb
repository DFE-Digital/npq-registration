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
      admin_users_path,
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
      "Users" => admin_users_path,
      "Unsynced users" => admin_unsynced_users_path,
      "Schools" => admin_schools_path,
    }.each do |text, href|
      # Check the links are present
      expect(page).to have_link(text, href:)
    end

    expect(page).not_to have_link("Feature Flags", href: "/admin/feature_flags")
    expect(page).not_to have_link("Feature Flags", href: "/admin/features")
    expect(page).not_to have_link("Admin Users", href: "/admin/admins")
    expect(page).not_to have_link("Settings", href: "/admin/settings")
  end

  scenario "when logged in as a super admin, it allows access to the admin homepage with super admin permissions" do
    visit "/admin"

    sign_in_as_super_admin

    page.click_link("Legacy Admin")

    expect(page).to have_link("Feature Flags", href: "/admin/feature_flags")
    expect(page).to have_link("New Feature Flags", href: "/admin/features")
    expect(page).to have_link("Admin Users", href: "/admin/admins")
    expect(page).to have_link("Settings", href: "/admin/settings")
  end

  scenario "when logged in as a super admin, the user can access the new feature flags interface" do
    sign_in_as_super_admin
    page.click_link("New Feature Flags")
    expect(page).to have_current_path("/admin/features")
  end

  # when logged in as a super admin, the user can:

    # - click on the view link for the registration open feature flag 
    # page.click_link "View Registration open"

    # - expect page to have text "Registration open"
    # expect(page).to have_content("Registration open")

    # - see that the registration open feature flag is currently set to true
    # expect Flipper::Feature.get(:registration_open).enabled?


    # - fill_in 'Confirm...', with: 'Registration open'
    # - click on the change state button for the registration open feature flag
    # - page.click_button "Change state"
    # - expect page to have text "You have turned the Registration open feature flag off."
    # - see that the registration open feature flag is currently set to false

  scenario "when logged in as a super admin, it allows management of admins", skip: "disabled" do
    sign_in_as_super_admin

    page.click_link("Legacy Admin")
    page.click_link("Admin Users")

    expect {
      page.click_link("Add new admin")
      expect(page).to have_current_path("/admin/admins/new")
      page.fill_in "Email", with: "foobar@example.com"
      page.click_button "Add admin"
    }.to change { User.admins.count }.by(1)

    expect(page).to have_current_path("/admin/admins")
    expect(page).to have_content("foobar@example.com")
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

  scenario "when logged in as a regular admin, it allows access to the users interface" do
    users = create_list(:user, 4, ecf_id: nil)

    sign_in_as_admin

    expect(page).to have_link("Users", href: admin_users_path)
    page.click_link("Users")
    expect(page).to have_current_path(admin_users_path)

    display_users = User.all.order(email: :asc)

    # Test application pagination
    display_users[0..2].each do |user|
      expect(page).to have_content(user.email)
    end

    page.find("[rel=next]").click

    display_users[3..].each do |user|
      expect(page).to have_content(user.email)
    end

    # Test application search and show page
    selected_user = users.sample

    successful_sync_log = selected_user.ecf_sync_request_logs.create!(
      status: :success,
      sync_type: :user_creation,
      created_at: 15.days.ago,
    )

    failed_sync_log = selected_user.ecf_sync_request_logs.create!(
      status: :failed,
      sync_type: :user_creation,
      error_messages: %w[foobar],
      created_at: 16.days.ago,
    )

    page.fill_in "Search records", with: selected_user.email
    page.click_button "Search"

    expect(page.find_all("table tbody tr").size).to be(1)

    click_link selected_user.email
    expect(page).to have_current_path("/admin/users/#{selected_user.id}")

    expect(page).to have_link("ECF Sync Log", href: "#ecf-sync-log")

    click_link "ECF Sync Log"
    within "#log-row-#{successful_sync_log.id}" do
      expect(page.text).to eq [
        "User Creation",
        successful_sync_log.created_at.to_formatted_s(:govuk_short),
        "Success",
        "-",
      ].join(" ")
    end

    within "#log-row-#{failed_sync_log.id}" do
      expect(page.text).to eq [
        "User Creation",
        failed_sync_log.created_at.to_formatted_s(:govuk_short),
        "Failed",
        failed_sync_log.error_messages.join(", "),
      ].join(" ")
    end

    expect(page).to have_link("Back", href: admin_users_url(q: selected_user.email))
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
