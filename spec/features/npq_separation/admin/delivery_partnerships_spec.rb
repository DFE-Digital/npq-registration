require "rails_helper"

RSpec.feature "NPQ Separation Admin Delivery Partnerships", type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }
  let!(:delivery_partner) { create(:delivery_partner) }
  let!(:lead_providers) { create_list(:lead_provider, 3) }
  let!(:cohorts) { [create(:cohort, :current), create(:cohort, :next)] }

  context "when not logged in" do
    scenario "delivery partnerships interface is inaccessible" do
      visit edit_npq_separation_admin_delivery_partner_delivery_partnerships_path(delivery_partner)
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as_admin }

    scenario "viewing the edit page for a delivery partner's partnerships" do
      visit npq_separation_admin_delivery_partners_path
      click_link "Assign lead providers", match: :first

      expect(page).to have_current_path(edit_npq_separation_admin_delivery_partner_delivery_partnerships_path(delivery_partner))

      within "main" do
        expect(page).to have_content("Add a lead provider")

        # All lead providers are displayed
        lead_providers.each do |lead_provider|
          expect(page).to have_content(lead_provider.name)
        end

        # Cohorts are hidden until a lead provider is selected
        expect(page).not_to have_content("Cohort")
      end
    end

    scenario "assigning lead providers and cohorts to a delivery partner" do
      lead_provider = lead_providers.first
      cohort = cohorts.first

      visit edit_npq_separation_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # Check the lead provider checkbox
      check lead_provider.name, visible: :all

      # Check the cohort checkbox for this lead provider
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        check cohort_label(cohort), visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(npq_separation_admin_delivery_partners_path)
      expect(page).to have_content("Delivery partner updated")
      expect(DeliveryPartnership.where(delivery_partner:, lead_provider:, cohort:)).to exist
    end

    scenario "removing a lead provider partnership" do
      # Create an existing partnership
      lead_provider = lead_providers.first
      cohort = cohorts.first

      delivery_partnership = create(:delivery_partnership,
                                    delivery_partner:,
                                    lead_provider:,
                                    cohort:)

      visit edit_npq_separation_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # The lead provider should be checked
      expect(page).to have_field("delivery_partner[lead_provider_id][]", with: lead_provider.id.to_s, checked: true, visible: :all)

      # The cohort should be checked
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        expect(page).to have_field(cohort_label(cohort), checked: true, visible: :all)
      end

      # Uncheck the lead provider (this should also uncheck all cohorts via JS)
      uncheck lead_provider.name, visible: :all

      click_button "Save"

      expect(page).to have_current_path(npq_separation_admin_delivery_partners_path)
      expect(page).to have_content("Delivery partner updated")
      expect(DeliveryPartnership.find_by(id: delivery_partnership.id)).to be_nil
    end

    scenario "removing a specific cohort from a lead provider partnership" do
      # Create existing partnerships for two cohorts
      lead_provider = lead_providers.first
      cohort1 = cohorts.first
      cohort2 = cohorts.second

      partnership1 = create(:delivery_partnership,
                            delivery_partner: delivery_partner,
                            lead_provider: lead_provider,
                            cohort: cohort1)

      partnership2 = create(:delivery_partnership,
                            delivery_partner: delivery_partner,
                            lead_provider: lead_provider,
                            cohort: cohort2)

      visit edit_npq_separation_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # The lead provider should be checked
      expect(page).to have_field("delivery_partner[lead_provider_id][]", with: lead_provider.id.to_s, checked: true, visible: :all)

      # Both cohorts should be checked
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        expect(page).to have_field(cohort_label(cohort1), checked: true, visible: :all)
        expect(page).to have_field(cohort_label(cohort2), checked: true, visible: :all)

        # Uncheck just the first cohort
        uncheck cohort_label(cohort1), visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(npq_separation_admin_delivery_partners_path)
      expect(page).to have_content("Delivery partner updated")
      expect(DeliveryPartnership.find_by(id: partnership1.id)).to be_nil
      expect(DeliveryPartnership.find_by(id: partnership2.id)).to be_present
    end

    scenario "cancel button redirects back to delivery partners index page" do
      visit edit_npq_separation_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      click_link "Cancel"
      expect(page).to have_current_path(npq_separation_admin_delivery_partners_path)
    end
  end

private

  def cohort_label(cohort)
    "Cohort #{cohort.start_year}/#{cohort.start_year - 1999}"
  end
end
