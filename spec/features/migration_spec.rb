require "rails_helper"

RSpec.feature "Migration", type: :feature, in_memory_rails_cache: true, rack_test_driver: true do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("MIGRATION_USERNAME").and_return("username")
    allow(ENV).to receive(:[]).with("MIGRATION_PASSWORD").and_return("password")
  end

  context "when not authenticated" do
    scenario "viewing the migrations page" do
      page.driver.browser.basic_authorize("wrong", "credentials")

      visit migrations_path

      expect(page).to have_http_status(:unauthorized)
    end
  end

  context "when migration username/password is not set for the environment" do
    scenario "viewing the migrations page" do
      allow(ENV).to receive(:[]).with("MIGRATION_USERNAME").and_return("")
      allow(ENV).to receive(:[]).with("MIGRATION_PASSWORD").and_return("")

      page.driver.browser.basic_authorize("", "")

      visit migrations_path

      expect(page).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated" do
    before { page.driver.browser.basic_authorize("username", "password") }

    scenario "viewing the migrations prior to running one" do
      visit migrations_path

      expect(page).to have_button("Run migration")

      expect(page).not_to have_content("A migration is currently in-progress")
      expect(page).not_to have_content("Latest migration")
    end

    scenario "running the first migration" do
      visit migrations_path

      click_button "Run migration"

      expect(page).to have_button("Run migration", disabled: true)

      expect(page).to have_content("A migration is currently in-progress")
      expect(page).to have_content("It was started less than a minute ago.")

      expect(page).not_to have_content("Latest migration")
    end

    context "with user data" do
      let(:users_counts) do
        {
          orphaned_ecf_users_count: 1,
          orphaned_npq_users_count: 4,
          duplicated_users_count: 3,
          matched_users_count: 2,
        }
      end

      before do
        users_counts[:orphaned_ecf_users_count].times { create(:ecf_user, :teacher, :with_application) }
        users_counts[:orphaned_npq_users_count].times { |trn| create(:user, trn:) }
        users_counts[:duplicated_users_count].times do
          ecf_user = create(:ecf_user, :teacher, :with_application)
          create(:user, trn: ecf_user.trn)
          create(:user, trn: ecf_user.trn)
        end
        users_counts[:matched_users_count].times do
          ecf_user = create(:ecf_user, :teacher, :with_application)
          create(:user, trn: ecf_user.trn)
        end

        visit migrations_path

        perform_enqueued_jobs do
          click_button "Run migration"
        end
      end

      scenario "viewing the general page state" do
        expect(page).not_to have_content("A migration is currently in-progress")

        expect(page).to have_button("Run migration")

        expect(page).to have_content("Latest migration")
        expect(page).to have_text("The latest migration was completed less than a minute ago.")
        expect(page).to have_text(/The migration took (.*) to complete./)
      end

      scenario "viewing the user reconcilliation metrics" do
        within(".govuk-summary-card.users") do
          expect(find("dt", text: "Count")).to have_sibling("dd", text: users_counts.values.sum)
          expect(find("dt", text: "Orphaned ecf count")).to have_sibling("dd", text: users_counts[:orphaned_ecf_users_count])
          expect(find("dt", text: "Orphaned npq count")).to have_sibling("dd", text: users_counts[:orphaned_npq_users_count])
          expect(find("dt", text: "Duplicate count")).to have_sibling("dd", text: users_counts[:duplicated_users_count])
          expect(find("dt", text: "Matched count")).to have_sibling("dd", text: users_counts[:matched_users_count])
        end
      end

      scenario "downloading the orphaned users report" do
        within(".govuk-summary-card.users") do
          click_on "Orphan report"
        end

        yaml = YAML.load(page.body)

        expect(yaml.map { |h| h.dig(:orphan, :class) }).to include("User", "Migration::Ecf::User")
      end
    end

    context "with application data" do
      let(:application_counts) do
        {
          orphaned_ecf_applications_count: 4,
          orphaned_npq_applications_count: 2,
          duplicated_applications_count: 1,
          matched_applications_count: 3,
        }
      end

      before do
        application_counts[:orphaned_ecf_applications_count].times { create(:ecf_npq_application) }
        application_counts[:orphaned_npq_applications_count].times { create(:application) }
        application_counts[:duplicated_applications_count].times do
          ecf_application = create(:ecf_npq_application)
          create(:application, ecf_id: ecf_application.id)
          create(:application, ecf_id: ecf_application.id)
        end
        application_counts[:matched_applications_count].times do
          ecf_application = create(:ecf_npq_application)
          create(:application, ecf_id: ecf_application.id)
        end

        visit migrations_path

        perform_enqueued_jobs do
          click_button "Run migration"
        end
      end

      scenario "viewing the general page state" do
        expect(page).not_to have_content("A migration is currently in-progress")

        expect(page).to have_button("Run migration")

        expect(page).to have_content("Latest migration")
        expect(page).to have_text("The latest migration was completed less than a minute ago.")
        expect(page).to have_text(/The migration took (.*) to complete./)
      end

      scenario "viewing the application reconcilliation metrics" do
        within(".govuk-summary-card.applications") do
          expect(find("dt", text: "Count")).to have_sibling("dd", text: application_counts.values.sum)
          expect(find("dt", text: "Orphaned ecf count")).to have_sibling("dd", text: application_counts[:orphaned_ecf_applications_count])
          expect(find("dt", text: "Orphaned npq count")).to have_sibling("dd", text: application_counts[:orphaned_npq_applications_count])
          expect(find("dt", text: "Duplicate count")).to have_sibling("dd", text: application_counts[:duplicated_applications_count])
          expect(find("dt", text: "Matched count")).to have_sibling("dd", text: application_counts[:matched_applications_count])
        end
      end

      scenario "downloading the orphaned applications report" do
        within(".govuk-summary-card.applications") do
          click_on "Orphan report"
        end

        yaml = YAML.load(page.body)

        expect(yaml.map { |h| h.dig(:orphan, :class) }).to include("Application", "Migration::Ecf::NpqApplication")
      end
    end
  end
end
