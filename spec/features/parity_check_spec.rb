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

      expect(page).to have_css("#response-time-chart")

      Migration::ParityCheck::ResponseComparison.by_lead_provider.each do |lead_provider_name, comparisons_by_description|
        within("##{lead_provider_name.parameterize}-section") do
          expect(page).to have_text(lead_provider_name)

          comparisons_by_description.each_key do |description|
            expect(page).to have_text(description)
            expect(page).not_to have_link
            expect(page).to have_text("EQUAL")
          end
        end
      end
    end

    scenario "viewing the completed parity check when it contains differences" do
      visit npq_separation_migration_parity_checks_path

      perform_enqueued_jobs do
        click_button "Run parity check"
      end

      different_comparison = create(:response_comparison, :different)

      # Reload to display the different comparison created manually
      visit current_path

      within("##{different_comparison.lead_provider_name.parameterize}-section") do
        details_path = response_comparison_npq_separation_migration_parity_checks_path(different_comparison)
        expect(page).to have_link(different_comparison.description, href: details_path)
        expect(page).to have_text("DIFFERENT")
      end
    end

    scenario "viewing the details of a response comparison" do
      visit npq_separation_migration_parity_checks_path

      perform_enqueued_jobs do
        click_button "Run parity check"
      end

      different_comparison = create(:response_comparison, :different)

      # Reload to display the different comparison created manually
      visit current_path

      click_link(different_comparison.description)

      expect(page).to have_css(".govuk-caption-xl", text: different_comparison.lead_provider_name)
      expect(page).to have_css("h1", text: different_comparison.description)

      expect(page).to have_text("Response diff")

      within("tbody tr:first") do
        expect(page).to have_text("Response time")
        expect(page).to have_text(/\d(ms)/)
        expect(page).to have_text("🚀 2x faster")
      end

      within("tbody tr:last") do
        expect(page).to have_text("Status code")
        expect(page).to have_text("200")
        expect(page).to have_text("201")
        expect(page).to have_text("DIFFERENT")
      end

      expect(page).to have_css(".diff", text: "response1 response2")
    end

    scenario "viewing the details of a response comparison when there are multiple pages" do
      visit npq_separation_migration_parity_checks_path

      perform_enqueued_jobs do
        click_button "Run parity check"
      end

      different_comparison = create(:response_comparison, :different, page: 1)
      lead_provider = different_comparison.lead_provider
      create(:response_comparison, :different, npq_response_body: "body", ecf_response_body: "body", page: 2, lead_provider:)
      create(:response_comparison, :equal, page: 3, lead_provider:)

      # Reload to display the different comparison created manually
      visit current_path

      click_link(different_comparison.description)

      expect(page).to have_css(".govuk-caption-xl", text: different_comparison.lead_provider_name)
      expect(page).to have_css("h1", text: different_comparison.description)

      expect(page).to have_text("Overview (3 pages)")

      within("tbody tr:first") do
        expect(page).to have_text("Equality check")
        expect(page).to have_text("DIFFERENT")
      end

      within("tbody tr:last") do
        expect(page).to have_text("Average response time")
        expect(page).to have_text("100ms")
        expect(page).to have_text("50ms")
        expect(page).to have_text("🚀 2x faster")
      end

      expect(page).to have_css(".govuk-grid-row", text: "Page 1\nECF: 200 NPQ: 201")

      expect(page).to have_css(".govuk-grid-row", text: "Page 2\nECF: 200 NPQ: 201")
      expect(page).to have_text("No difference")

      expect(page).not_to have_text("Page 3")
    end
  end
end
