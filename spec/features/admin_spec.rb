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
    expect(page).not_to have_link("Admin Users", href: "/admin/admins")
    expect(page).not_to have_link("Settings", href: "/admin/settings")
  end

  scenario "when logged in as a super admin, it allows access to the admin homepage with super admin permissions" do
    visit "/admin"

    sign_in_as_super_admin

    page.click_link("Admin")

    expect(page).to have_link("Feature Flags", href: "/admin/feature_flags")
    expect(page).to have_link("Admin Users", href: "/admin/admins")
    expect(page).to have_link("Settings", href: "/admin/settings")
  end

  scenario "when logged in as a super admin, it allows management of admins", skip: "disabled" do
    sign_in_as_super_admin

    page.click_link("Admin")
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

    page.click_link("Admin")
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

    expect(page).to have_link("Sync user and applications to ECF")

    expect {
      click_link "Sync user and applications to ECF"
    }.to enqueue_job(ApplicationSubmissionJob).with(user: selected_application.user, email_template: nil)
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

    expect(page).to have_link("Sync user and applications to ECF")

    expect {
      click_link "Sync user and applications to ECF"
    }.to enqueue_job(ApplicationSubmissionJob).with(user: selected_user, email_template: nil)
  end

  scenario "when logged in as a regular admin, it allows access to the unsynced applications interface" do
    sign_in_as_admin

    expect(page).to have_link("Unsynced applications", href: admin_unsynced_applications_path)
    page.click_link("Unsynced applications")
    expect(page).to have_current_path(admin_unsynced_applications_path)
    expect(page).to have_content("All applications have been successfuly linked with an ECF user.")

    # when there are some unsynced records
    unsynced_applications = create_list(:application, 2, ecf_id: nil)
    create_list(:application, 1) # synced applications

    page.click_link("Unsynced applications")

    unsynced_applications.each do |app|
      expect(page).to have_content(app.user.email)
    end

    expect(page.find_all("table tbody tr").size).to eql(unsynced_applications.size)

    unsynced_application_to_view = unsynced_applications.first

    failed_sync_log = unsynced_application_to_view.ecf_sync_request_logs.create!(
      status: :failed,
      sync_type: :application_creation,
      error_messages: %w[foobar],
      created_at: 16.days.ago,
    )

    # viewing an unsynced record
    page.click_link unsynced_application_to_view.user.email
    expect(page).to have_current_path("/admin/applications/#{unsynced_application_to_view.id}")

    expect(page).to have_content(unsynced_application_to_view.user.full_name)

    expect(page).to have_link("ECF Sync Log", href: "#ecf-sync-log")

    click_link "ECF Sync Log"
    within "#log-row-#{failed_sync_log.id}" do
      expect(page.text).to eq [
        "Application Creation",
        failed_sync_log.created_at.to_formatted_s(:govuk_short),
        "Failed",
        failed_sync_log.error_messages.join(", "),
      ].join(" ")
    end

    expect(page).to have_link("Back", href: admin_unsynced_applications_url)
  end

  scenario "when logged in as a regular admin, it allows access to the unsynced users interface" do
    sign_in_as_admin

    expect(page).to have_link("Unsynced users", href: admin_unsynced_users_path)
    page.click_link("Unsynced users")
    expect(page).to have_current_path(admin_unsynced_users_path)
    expect(page).to have_content("All users have been successfuly linked with an ECF user.")

    # An unsynced user without applications shouldn't appear in the list
    unsynced_without_application = create(:user, ecf_id: nil)
    # A synced user shouldn't appear in the list
    synced_user = create(:user)
    create(:application, user: synced_user)

    # Unsynced users with applications should appear in the list.
    unsynced_users = create_list(:user, 2, ecf_id: nil)
    unsynced_users.each do |unsynced_user|
      create_list(:application, 2, user: unsynced_user)
    end

    page.click_link("Unsynced users")

    expect(page).not_to have_content(unsynced_without_application.email)
    expect(page).not_to have_content(synced_user.email)

    unsynced_users.each do |user|
      expect(page).to have_content(user.email)
    end

    expect(page.find_all("table tbody tr").size).to eql(unsynced_users.size)

    unsynced_user_to_view = unsynced_users.first

    failed_sync_log = unsynced_user_to_view.ecf_sync_request_logs.create!(
      status: :failed,
      sync_type: :user_creation,
      error_messages: %w[foobar],
      created_at: 16.days.ago,
    )

    # viewing an unsynced record
    page.click_link unsynced_user_to_view.email
    expect(page).to have_current_path("/admin/users/#{unsynced_user_to_view.id}")

    expect(page).to have_content(unsynced_user_to_view.full_name)

    expect(page).to have_link("ECF Sync Log", href: "#ecf-sync-log")

    click_link "ECF Sync Log"
    within "#log-row-#{failed_sync_log.id}" do
      expect(page.text).to eq [
        "User Creation",
        failed_sync_log.created_at.to_formatted_s(:govuk_short),
        "Failed",
        failed_sync_log.error_messages.join(", "),
      ].join(" ")
    end

    expect(page).to have_link("Back", href: admin_unsynced_users_url)
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
end
