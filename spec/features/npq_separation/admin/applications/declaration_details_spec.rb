require "rails_helper"

RSpec.feature "Application declaration details", :versioning, type: :feature do
  include Helpers::AdminLogin

  let(:application) { create(:application) }

  context "when not logged in" do
    scenario "viewing declaration details" do
      visit(npq_separation_admin_application_path(application))
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as an admin" do
    before do
      sign_in_as(create(:admin))
    end

    scenario "viewing declaration details" do
      started_declaration = create(:declaration, :from_ecf, :with_secondary_delivery_partner, application:)

      completed_declaration = create(:declaration, :completed, application:)
      completed_declaration.mark_eligible!

      payable_statement = create(:statement, :payable)
      payable_declaration = create(:declaration, :payable, application:, statement: payable_statement)
      paid_statement = create(:statement, :paid, declaration: payable_declaration)

      visit(npq_separation_admin_application_path(application))
      click_link "Declaration details"

      expect(page).to have_css("h1", text: "Declaration details")

      summary_cards = all(".govuk-summary-card")
      expect(summary_cards).to have_attributes(length: 3)

      within(summary_cards[0]) do |summary_card|
        expect(summary_card).to have_css(".govuk-summary-card__title", text: "Started (Submitted)")

        within(find(".govuk-summary-list")) do |summary_list|
          expect(summary_list).to have_summary_item("Declaration ID", started_declaration.ecf_id)
          expect(summary_list).to have_summary_item("Declaration date", started_declaration.declaration_date.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Declaration cohort", started_declaration.cohort.start_year)
          expect(summary_list).to have_summary_item("Provider", started_declaration.lead_provider.name)
          expect(summary_list).to have_summary_item("Delivery partner", started_declaration.delivery_partner.name)
          expect(summary_list).to have_summary_item("Secondary delivery partner", started_declaration.secondary_delivery_partner.name)
          expect(summary_list).to have_summary_item("Created at", started_declaration.created_at.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Updated at", started_declaration.updated_at.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Statements", "")
        end
      end

      within(summary_cards[1]) do |summary_card|
        expect(summary_card).to have_css(".govuk-summary-card__title", text: "Completed (Eligible)")

        within(find(".govuk-summary-list")) do |summary_list|
          expect(summary_list).to have_summary_item("Declaration ID", "-")
          expect(summary_list).to have_summary_item("Declaration date", completed_declaration.declaration_date.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Declaration cohort", completed_declaration.cohort.start_year)
          expect(summary_list).to have_summary_item("Provider", completed_declaration.lead_provider.name)
          expect(summary_list).to have_summary_item("Delivery partner", completed_declaration.delivery_partner.name)
          expect(summary_list).to have_summary_item("Secondary delivery partner", "")
          expect(summary_list).to have_summary_item("Created at", completed_declaration.created_at.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Updated at", completed_declaration.updated_at.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Statements", "")
        end

        expect(summary_card).to have_css(".moj-timeline__item", text: /Submitted\s+#{completed_declaration.created_at.to_fs(:govuk_short)}/)
        expect(summary_card).to have_css(".moj-timeline__item", text: /Eligible\s+#{completed_declaration.created_at.to_fs(:govuk_short)}/)
      end

      within(summary_cards[2]) do
        within(find(".govuk-summary-list")) do |summary_list|
          expect(summary_list).to have_summary_item(
            "Statements",
            "#{Date::MONTHNAMES[payable_statement.month]} #{payable_statement.year}" \
            "\n" \
            "#{Date::MONTHNAMES[paid_statement.month]} #{paid_statement.year}",
          )
        end
      end

      click_link("#{Date::MONTHNAMES[payable_statement.month]} #{payable_statement.year}")
      expect(page).to have_current_path(npq_separation_admin_finance_statement_path(payable_statement))

      visit(npq_separation_admin_application_declarations_path(application))
      click_link("#{Date::MONTHNAMES[paid_statement.month]} #{paid_statement.year}")
      expect(page).to have_current_path(npq_separation_admin_finance_statement_path(paid_statement))
    end
  end
end
