require "rails_helper"

RSpec.feature "Backfill declaration delivery partners", :no_js, type: :feature do
  include Helpers::AdminLogin
  include Helpers::BulkOperations

  let(:admin) { create(:admin) }
  let(:filename) { File.basename(file.path) }
  let(:lead_provider) { LeadProvider.first }
  let(:cohort) { create(:cohort, start_year: 2023) }
  let(:bulk_operation) { create(:backfill_declaration_delivery_partners_bulk_operation, admin: create(:admin)) }
  let(:instance) { described_class.new(bulk_operation:) }
  let(:declaration) { create(:declaration, lead_provider:, cohort:, delivery_partner: nil) }
  let(:delivery_partner_1) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
  let(:delivery_partner_2) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }

  let(:file) do
    tempfile <<~CSV
      Declaration ID,Primary Delivery Partner ID,Secondary Delivery Partner ID
      #{declaration.ecf_id},#{delivery_partner_1.ecf_id},#{delivery_partner_2.ecf_id}
    CSV
  end

  context "when not logged in" do
    scenario "bulk operations index page is inaccessible" do
      visit npq_separation_admin_bulk_operations_path
      expect(page).to have_current_path(sign_in_path)
    end

    scenario "Backfill declaration delivery partners page is inaccessible" do
      visit npq_separation_admin_bulk_operations_backfill_declaration_delivery_partners_path
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as(admin) }

    scenario "Backfilling declaration delivery partners" do
      visit npq_separation_admin_path
      click_link "Bulk changes"
      click_link "Backfill declaration delivery partners"

      expect(page).to have_content "No files have been uploaded"

      attach_file "file", file.path
      click_button "Upload file"

      expect(page).to have_content "File #{filename} uploaded successfully"

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "1")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
      end

      visit npq_separation_admin_bulk_operations_backfill_declaration_delivery_partners_path
      perform_enqueued_jobs do
        click_button "Backfill declaration delivery partners"
      end

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "1")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
        expect(summary_list).to have_summary_item("Ran by", "#{admin.full_name} (#{admin.email})")
      end

      expect(page).to have_content "#{declaration.ecf_id}Declaration updated"
      expect(page).not_to have_button("Backfill declaration delivery partners")
      expect(declaration.reload.delivery_partner).to eq(delivery_partner_1)
      expect(declaration.reload.secondary_delivery_partner).to eq(delivery_partner_2)
    end

    scenario "when the bulk operation has started but not finished" do
      visit npq_separation_admin_bulk_operations_backfill_declaration_delivery_partners_path
      attach_file "file", file.path
      click_button "Upload file"
      click_button "Backfill declaration delivery partners"
      click_link filename

      expect(page).to have_content "The bulk operation is in progress."
    end
  end
end
