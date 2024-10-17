require "rails_helper"

RSpec.feature "Parity check", :in_memory_rails_cache, :rack_test_driver, type: :feature do
  include Helpers::AdminLogin

  before do
    create_matching_ecf_lead_providers

    stub_request(:get, %r{http://(npq|ecf).example.com/api/.*})
  end

  context "when not authenticated" do
    scenario "viewing the parity checks page" do
      visit npq_separation_migration_parity_checks_path

      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when authenticated" do
    before { sign_in_as(create(:super_admin)) }

    scenario "viewing the parity checks prior to running one" do
      visit npq_separation_migration_parity_checks_path

      expect(page).to have_button("Run parity check")

      expect(page).not_to have_content("A parity check is currently in-progress")
      expect(page).not_to have_content("Completed parity check")
    end

    scenario "running a parity check" do
      visit npq_separation_migration_parity_checks_path

      click_button "Run parity check"

      expect(page).to have_button("Run parity check", disabled: true)

      expect(page).to have_content("A parity check is currently in-progress")
      expect(page).to have_content("It was started less than a minute ago.")

      expect(page).not_to have_content("Completed parity check")
    end

    scenario "viewing the completed parity check" do
      visit npq_separation_migration_parity_checks_path

      perform_enqueued_jobs do
        click_button "Run parity check"
      end

      expect(page).not_to have_content("A parity check is currently in-progress")
      expect(page).not_to have_content("It was started less than a minute ago.")

      expect(page).to have_content("Completed parity check")

      expect(page).to have_content("The latest parity check was completed less than a minute ago.")
      expect(page).to have_text(/The parity check took (.*) to complete./)
    end
  end
end
