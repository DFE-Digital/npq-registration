require "rails_helper"

RSpec.feature "Listing and viewing course providers", type: :feature do
  include Helpers::AdminLogin

  before do
    create_list(:lead_provider, 5)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of course providers" do
    visit(npq_separation_admin_lead_providers_path)

    expect(page).to have_css("h1", text: "Providers")

    LeadProvider.all.find_each do |lead_provider|
      expect(page).to have_link(lead_provider.name, href: npq_separation_admin_lead_provider_path(lead_provider))
    end
  end

  scenario "viewing course provider details" do
    cohort_2025 = create(:cohort, start_year: 2025)
    cohort_2024 = create(:cohort, start_year: 2024)
    cohort_2023 = create(:cohort, start_year: 2023)
    lead_provider = LeadProvider.order(:name).first
    delivery_partner_25 = create(:delivery_partner, lead_providers: { cohort_2025 => lead_provider })
    delivery_partner_24 = create(:delivery_partner, lead_providers: { cohort_2024 => lead_provider })
    delivery_partner_23 = create(:delivery_partner, lead_providers: { cohort_2023 => lead_provider })

    visit(npq_separation_admin_lead_providers_path)
    click_link(lead_provider.name)

    expect(page).to have_css("h1", text: lead_provider.name)
    expect(page).to have_css("h2", text: "Cohort 2025 to 2026")
    expect(page).to have_table(with_rows: ["Delivery partner" => delivery_partner_25.name])

    click_link("Cohort 2024 to 2025")
    expect(page).to have_table(with_rows: ["Delivery partner" => delivery_partner_24.name])

    click_link("Cohort 2023 to 2024")
    expect(page).to have_table(with_rows: ["Delivery partner" => delivery_partner_23.name])

    within "#side-navigation" do
      click_link "Course providers"
    end
    expect(page).to have_current_path(npq_separation_admin_lead_providers_path)
  end
end
