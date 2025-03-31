require "rails_helper"

RSpec.feature "NPQ Separation Admin Delivery Partners", type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }

  context "when not logged in" do
    scenario "delivery partners interface is inaccessible" do
      visit npq_separation_admin_delivery_partners_path
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as_admin }

    scenario "when logged in as admin, it displays the list of delivery partners" do
      delivery_partners = create_list(:delivery_partner, 11).sort_by(&:name)

      visit npq_separation_admin_delivery_partners_path

      expect(page).to have_content("Delivery partners")

      # Test delivery partner pagination
      delivery_partners[0..9].each do |delivery_partner|
        expect(page).to have_content(delivery_partner.ecf_id)
        expect(page).to have_content(delivery_partner.name)
        expect(page).to have_link("Update", href: edit_npq_separation_admin_delivery_partner_path(delivery_partner))
      end

      page.find("[rel=next]").click

      delivery_partners[10..].each do |delivery_partner|
        expect(page).to have_content(delivery_partner.name)
      end
    end

    scenario "when logged in as admin, it allows creating a new delivery partner" do
      visit npq_separation_admin_delivery_partners_path
      click_link "Add a delivery partner"

      expect(page).to have_content("Add a delivery partner")

      expect {
        fill_in "Enter delivery partner name", with: "New Test Partner"
        click_button "Save"
      }.to change(DeliveryPartner, :count).by(1)

      expect(page).to have_content("Delivery partners")
      expect(page).to have_content("Delivery partner created")
      expect(page).to have_content("New Test Partner")
    end

    scenario "when creating a delivery partner with invalid data, it shows validation errors" do
      visit npq_separation_admin_delivery_partners_path
      click_link "Add a delivery partner"

      fill_in "Enter delivery partner name", with: ""
      click_button "Save"

      expect(page).to have_content("Add a delivery partner")
      expect(page).to have_content("can't be blank")
    end

    scenario "when logged in as admin, it allows updating an existing delivery partner" do
      create(:delivery_partner, name: "Original Partner Name")

      visit npq_separation_admin_delivery_partners_path
      click_link "Update"

      expect(page).to have_content("Update delivery partner name")
      expect(page).to have_content("Original Partner Name")

      fill_in "Enter delivery partner name", with: "Updated Partner Name"
      click_button "Save"

      expect(page).to have_content("Delivery partners")
      expect(page).to have_content("Delivery partner updated")
      expect(page).to have_content("Updated Partner Name")
      expect(page).not_to have_content("Original Partner Name")
    end

    scenario "when updating a delivery partner with invalid data, it shows validation errors" do
      create(:delivery_partner, name: "Original Partner Name")

      visit npq_separation_admin_delivery_partners_path
      click_link "Update"

      fill_in "Enter delivery partner name", with: ""
      click_button "Save"

      expect(page).to have_content("Update delivery partner name")
      expect(page).to have_content("can't be blank")
    end

    scenario "cancel button on new form redirects back to index page" do
      visit new_npq_separation_admin_delivery_partner_path

      click_link "Cancel"
      expect(page).to have_current_path(npq_separation_admin_delivery_partners_path)
    end

    scenario "cancel button on edit form redirects back to index page" do
      delivery_partner = create(:delivery_partner)

      visit edit_npq_separation_admin_delivery_partner_path(delivery_partner)

      click_link "Cancel"
      expect(page).to have_current_path(npq_separation_admin_delivery_partners_path)
    end
  end
end
