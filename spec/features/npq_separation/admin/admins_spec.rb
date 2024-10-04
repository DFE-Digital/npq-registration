require "rails_helper"

RSpec.feature "Administering admins", type: :feature do
  include Helpers::AdminLogin

  let(:super_admin) { create :super_admin }

  scenario "is not authorized for regular admins" do
    sign_in_as(create(:admin))

    visit(npq_separation_admin_admins_path)
    expect(page).to have_text("Unauthorized")
  end

  scenario "listing current admins" do
    admins = create_list(:admin, 2)
    super_admins = create_list(:super_admin, 2)

    sign_in_as(super_admin)
    visit(npq_separation_admin_admins_path)

    (admins + super_admins).each do |admin|
      expect(page).to have_text(admin.full_name)
    end
  end

  scenario "creating a new admin" do
    sign_in_as(super_admin)
    visit(npq_separation_admin_admins_path)
    click_on "Add new admin"

    fill_in "Email address", with: "new@example.com"
    fill_in "Full name", with: "New Admin"
    click_on "Add admin"

    expect(page).to have_text("new@example.com")
    expect(page).to have_text("New Admin")
  end

  scenario "promoting an admin to super admin" do
    admin = create :admin
    sign_in_as(super_admin)
    visit(npq_separation_admin_admins_path)

    expect { click_on "Make Super Admin" }.to change { admin.reload.super_admin? }.from(false).to(true)
  end

  scenario "deleting an admin" do
    admin = create :admin
    sign_in_as(super_admin)
    visit(npq_separation_admin_admins_path)

    within "tr", text: admin.email do
      expect { click_on "Delete" }.to change(Admin, :count).by(-1)
    end
  end

  scenario "no link to delete a super admin" do
    another_super_admin = create :super_admin
    sign_in_as(super_admin)
    visit(npq_separation_admin_admins_path)

    within "tr", text: another_super_admin.email do
      expect(page).not_to have_link("Delete")
    end
  end
end
