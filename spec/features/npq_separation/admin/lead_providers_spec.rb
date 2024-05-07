require "rails_helper"

RSpec.feature "Listing and viewing lead providers", type: :feature do
  include Helpers::AdminLogin

  before do
    create_list(:lead_provider, 5)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of lead providers" do
    visit(npq_separation_admin_lead_providers_path)

    expect(page).to have_css("h1", text: "Lead providers")

    LeadProvider.all.find_each do |lead_provider|
      expect(page).to have_link(lead_provider.name, href: npq_separation_admin_lead_provider_path(lead_provider))
    end
  end

  scenario "viewing lead provider details" do
    visit(npq_separation_admin_lead_providers_path)

    lead_provider = LeadProvider.first
    statement = create(:statement, lead_provider:)

    click_link(lead_provider.name)

    expect(page).to have_css("h1", text: lead_provider.name)
    expect(page).to have_link("View all statements", href: npq_separation_admin_finance_statements_path)

    within("table tbody tr") do |summary_list|
      expect(summary_list).to have_text(statement.id)
      expect(summary_list).to have_text(statement.cohort.start_year)
      expect(summary_list).to have_text(statement.state.capitalize)
      expect(summary_list).to have_link("View", href: npq_separation_admin_finance_statement_path(statement))
    end
  end
end
