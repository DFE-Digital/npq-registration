require "rails_helper"

RSpec.feature "Migration", :ecf_api_disabled, :in_memory_rails_cache, :rack_test_driver, type: :feature do
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

        within first(".data-migration-lead_provider") do
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
          expect(page).to have_css(".percentage-successfully-migrated", text: "66%")

          data_migration = Migration::DataMigration.find_by(model: :lead_provider)
          expect(page).to have_link("Failures report", href: download_report_npq_separation_migration_migrations_path(data_migration.model))
        end
      end
    end

    context "when migrating cohorts" do
      before do
        ecf_cohort1 = create(:ecf_migration_cohort, start_year: 2026)
        ecf_cohort2 = create(:ecf_migration_cohort, start_year: 2029)

        create(:cohort, ecf_id: ecf_cohort1.id, start_year: ecf_cohort1.start_year)
        create(:cohort, ecf_id: ecf_cohort2.id, start_year: ecf_cohort2.start_year)

        create(:ecf_migration_cohort, registration_start_date: nil)
      end

      scenario "running a migration" do
        visit npq_separation_migration_migrations_path

        click_button "Run migration"

        within first(".data-migration-cohort") do
          expect(page).to have_css(".govuk-task-list__name-and-hint", text: "Cohort")
          expect(page).to have_css(".govuk-task-list__status", text: "Pending")
        end
      end

      scenario "viewing the completed migration" do
        visit npq_separation_migration_migrations_path

        perform_enqueued_jobs do
          click_button "Run migration"
        end

        within ".data-migration-cohort" do
          expect(page).to have_css(".total-count", text: 3)
          expect(page).to have_css(".failure-count", text: 1)
          expect(page).to have_css(".percentage-successfully-migrated", text: "66%")

          data_migration = Migration::DataMigration.find_by(model: :cohort)
          expect(page).to have_link("Failures report", href: download_report_npq_separation_migration_migrations_path(data_migration.model))
        end
      end
    end

    context "when migrating statements" do
      before do
        ecf_statement1 = create(:ecf_migration_statement, name: "July 2026")
        ecf_statement2 = create(:ecf_migration_statement, name: "January 2030")

        cohort1 = create(:cohort, ecf_id: ecf_statement1.cohort_id, start_year: ecf_statement1.cohort.start_year)
        cohort2 = create(:cohort, ecf_id: ecf_statement2.cohort_id, start_year: ecf_statement2.cohort.start_year)

        lead_provider1 = create(:lead_provider, ecf_id: ecf_statement1.npq_lead_provider.id)
        lead_provider2 = create(:lead_provider, ecf_id: ecf_statement2.npq_lead_provider.id)

        create(:statement, ecf_id: ecf_statement1.id, month: 7, year: 2026, lead_provider: lead_provider1, cohort: cohort1)
        create(:statement, ecf_id: ecf_statement2.id, month: 1, year: 2030, lead_provider: lead_provider2, cohort: cohort2)

        create(:ecf_migration_statement, output_fee: nil)
      end

      scenario "running a migration" do
        visit npq_separation_migration_migrations_path

        click_button "Run migration"

        within first(".data-migration-statement") do
          expect(page).to have_css(".govuk-task-list__name-and-hint", text: "Statement")
          expect(page).to have_css(".govuk-task-list__status", text: "Pending")
        end
      end

      scenario "viewing the completed migration" do
        visit npq_separation_migration_migrations_path

        perform_enqueued_jobs do
          click_button "Run migration"
        end

        within ".data-migration-statement" do
          expect(page).to have_css(".total-count", text: 3)
          expect(page).to have_css(".failure-count", text: 1)
          expect(page).to have_css(".percentage-successfully-migrated", text: "66%")

          data_migration = Migration::DataMigration.find_by(model: :statement)
          expect(page).to have_link("Failures report", href: download_report_npq_separation_migration_migrations_path(data_migration.model))
        end
      end
    end

    context "when migrating users" do
      before do
        ecf_user1 = create(:ecf_migration_user, :npq)
        ecf_user2 = create(:ecf_migration_user, :npq)

        create(:user, :with_random_name, ecf_id: ecf_user1.id, email: ecf_user1.email)
        create(:user, :with_random_name, ecf_id: ecf_user2.id, email: ecf_user2.email)

        # Duplicate users with ecf_id
        ecf_user = create(:ecf_migration_user, :npq)
        create(:user, ecf_id: ecf_user.id)
        create(:user, ecf_id: ecf_user.id)
      end

      scenario "running a migration" do
        visit npq_separation_migration_migrations_path

        click_button "Run migration"

        within first(".data-migration-user") do
          expect(page).to have_css(".govuk-task-list__name-and-hint", text: "User")
          expect(page).to have_css(".govuk-task-list__status", text: "Pending")
        end
      end

      scenario "viewing the completed migration" do
        visit npq_separation_migration_migrations_path

        perform_enqueued_jobs do
          click_button "Run migration"
        end

        within ".data-migration-user" do
          expect(page).to have_css(".total-count", text: 3)
          expect(page).to have_css(".failure-count", text: 1)
          expect(page).to have_css(".percentage-successfully-migrated", text: "66%")
        end
      end
    end
  end
end
