require "rails_helper"

RSpec.feature "Migration", type: :feature, in_memory_rails_cache: true, rack_test_driver: true do
  include Helpers::AdminLogin

  context "when not authenticated" do
    scenario "viewing the migrations page" do
      visit npq_separation_migration_migrations_path

      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when authenticated" do
    before { sign_in_as(create(:super_admin)) }

    scenario "viewing the migrations prior to running one" do
      visit npq_separation_migration_migrations_path

      expect(page).to have_button("Run migration")

      expect(page).not_to have_content("A migration is currently in-progress")
      expect(page).not_to have_content("Completed migration")
    end

    scenario "running a migration" do
      visit npq_separation_migration_migrations_path

      click_button "Run migration"

      expect(page).to have_button("Run migration", disabled: true)

      expect(page).to have_content("A migration is currently in-progress")
      expect(page).to have_content("It was started less than a minute ago.")

      expect(page).not_to have_content("Completed migration")
    end

    scenario "viewing the completed migration" do
      visit npq_separation_migration_migrations_path

      perform_enqueued_jobs do
        click_button "Run migration"
      end

      expect(page).not_to have_content("A migration is currently in-progress")
      expect(page).not_to have_content("It was started less than a minute ago.")

      expect(page).to have_content("Completed migration")

      expect(page).to have_content("The latest migration was completed less than a minute ago.")
      expect(page).to have_text(/The migration took (.*) to complete./)
    end

    context "when migrating lead providers" do
      before do
        ecf_npq_lead_provider1 = create(:ecf_migration_npq_lead_provider)
        ecf_npq_lead_provider2 = create(:ecf_migration_npq_lead_provider)

        create(:lead_provider, ecf_id: ecf_npq_lead_provider1.id)
        create(:lead_provider, ecf_id: ecf_npq_lead_provider2.id)

        create(:ecf_migration_npq_lead_provider)
      end

      scenario "running a migration" do
        visit npq_separation_migration_migrations_path

        click_button "Run migration"

        within ".data-migration-lead_provider" do
          expect(page).to have_css(".govuk-task-list__name-and-hint", text: "Lead provider")
          expect(page).to have_css(".govuk-task-list__status", text: "Pending")
        end
      end

      scenario "viewing the completed migration" do
        visit npq_separation_migration_migrations_path

        perform_enqueued_jobs do
          click_button "Run migration"
        end

        within ".data-migration-lead_provider" do
          expect(page).to have_css(".total-count", text: 3)
          expect(page).to have_css(".failure-count", text: 1)
          expect(page).to have_css(".percentage-successfully-migrated", text: "67%")
        end
      end
    end
  end
end
