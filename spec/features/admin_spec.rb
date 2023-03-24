require "rails_helper"

RSpec.feature "admin", type: :feature do
  include_context "Enable Get An Identity integration"

  let(:admin) { create(:admin, :with_ecf_id) }

  around do |example|
    Capybara.current_driver = :rack_test
    previous_pagination = Pagy::DEFAULT[:items]
    Pagy::DEFAULT[:items] = 3
    example.run
    Pagy::DEFAULT[:items] = previous_pagination
    Capybara.current_driver = Capybara.default_driver
  end

  def sign_in_as_admin
    expect(page.current_path).to eql(sign_in_path)

    page.fill_in "What’s your email address?", with: admin.email
    page.click_button "Sign in"
    expect(page.current_path).to eql("/session/sign-in-code")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"
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
      expect(page.current_path).to eql(sign_in_path)
    end
  end

  scenario "when logged in as a regular admin, it allows access to the admin homepage" do
    visit "/admin"

    sign_in_as_admin

    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

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

    expect(page).to_not have_link("Feature Flags", href: "/admin/feature_flags")

    admin.update!(flipper_admin_access: true)

    page.click_link("Admin")

    expect(page).to have_link("Feature Flags", href: "/admin/feature_flags")
  end

  scenario "when logged in as a regular admin, it allows access to the dashboard" do
    create_list :application, 4

    visit "/admin"

    sign_in_as_admin

    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    expect(page).to have_link("Dashboard", href: admin_path)
    page.click_link("Dashboard")
    expect(page.current_path).to eql(admin_path)
  end

  scenario "when logged in as a regular admin, it allows access to the applications interfaces" do
    applications = create_list :application, 4

    visit "/admin"

    sign_in_as_admin

    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    expect(page).to have_link("Applications", href: admin_applications_path)
    page.click_link("Applications")
    expect(page.current_path).to eql(admin_applications_path)

    # Test application pagination
    applications[0..2].each do |app|
      expect(page).to have_content(app.user.email)
    end

    page.find("[aria-label=next]").click

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

    expect(page.find_all("table tbody tr").size).to eql(1)

    click_link selected_application.user.email
    expect(page.current_path).to eql(admin_application_path(id: selected_application.id))

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
    }.to enqueue_job(ApplicationSubmissionJob).with(user: selected_application.user)
  end

  scenario "when logged in as a regular admin, it allows access to the users interface" do
    users = create_list(:user, 4)

    visit "/admin"

    sign_in_as_admin

    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    expect(page).to have_link("Users", href: admin_users_path)
    page.click_link("Users")
    expect(page.current_path).to eql(admin_users_path)

    display_users = User.all

    # Test application pagination
    display_users[0..2].each do |user|
      expect(page).to have_content(user.email)
    end

    page.find("[aria-label=next]").click

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

    expect(page.find_all("table tbody tr").size).to eql(1)

    click_link selected_user.email
    expect(page.current_path).to eql("/admin/users/#{selected_user.id}")

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
    }.to enqueue_job(ApplicationSubmissionJob).with(user: selected_user)
  end

  scenario "when logged in as a regular admin, it allows access to the unsynced applications interface" do
    visit "/admin"

    sign_in_as_admin

    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    expect(page).to have_link("Unsynced applications", href: admin_unsynced_applications_path)
    page.click_link("Unsynced applications")
    expect(page.current_path).to eql(admin_unsynced_applications_path)
    expect(page).to have_content("All applications have been successfuly linked with an ECF user.")

    # when there are some unsynced records
    unsynced_applications = create_list(:application, 2)
    create_list(:application, 1, :with_ecf_id) # synced applications

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
    expect(page.current_path).to eql("/admin/applications/#{unsynced_application_to_view.id}")

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
    visit "/admin"

    sign_in_as_admin

    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    expect(page).to have_link("Unsynced users", href: admin_unsynced_users_path)
    page.click_link("Unsynced users")
    expect(page.current_path).to eql(admin_unsynced_users_path)
    expect(page).to have_content("All users have been successfuly linked with an ECF user.")

    # An unsynced user without applications shouldn't appear in the list
    unsynced_without_application = create(:user)
    # A synced user shouldn't appear in the list
    synced_user = create(:user, :with_ecf_id)
    create(:application, user: synced_user)

    # Unsynced users with applications should appear in the list.
    unsynced_users = create_list(:user, 2)
    unsynced_users.each do |unsynced_user|
      create_list(:application, 2, user: unsynced_user)
    end

    page.click_link("Unsynced users")

    expect(page).to_not have_content(unsynced_without_application.email)
    expect(page).to_not have_content(synced_user.email)

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
    expect(page.current_path).to eql("/admin/users/#{unsynced_user_to_view.id}")

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

    visit "/admin"

    sign_in_as_admin

    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    expect(page).to have_link("Schools", href: admin_schools_path)
    page.click_link("Schools")
    expect(page.current_path).to eql(admin_schools_path)
  end
end
