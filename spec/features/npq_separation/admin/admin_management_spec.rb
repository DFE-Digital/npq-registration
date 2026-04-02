require "rails_helper"

RSpec.feature "admin management", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:super_admin) { create(:super_admin) }

  before { sign_in_as(super_admin) }

  scenario "adding a new admin" do
    given_i_am_on_the_admin_index
    click_link("Add new admin")
    and_i_should_be_on_the_add_new_admin_page

    when_i_fill_in_the_new_admin_form_with(full_name: "Joey Joe", email: "joey-joe@shabadoo.org")
    click_button("Add admin")

    then_the_latest_admin_has_the_correct_details(full_name: "Joey Joe", email: "joey-joe@shabadoo.org")
  end

  # this doesn't exist currently, no ability to change admins' email addresses
  scenario "editing an admin's email", skip: "this doesn't exist currently, no ability to change admins' email addresses" do
    given_the_following_admin_exists(full_name: "Joey Joe", email: "joey-joe@shabadoo.org")
    visit(npq_separation_admin_admins_path)
    and_i_select_them_from_the_list_of_admins(email: "joey-joe@shabadoo.org")

    when_i_change_their_full_name_to("Joey Joseph")
    and_i_change_their_email_to("joey-joseph@shabadoo.org")
    click_button("Update admin")

    then_the_admin_record_should_have_the_correct_details(full_name: "Joey Joseph", email: "joey-joseph@shabadoo.org")
  end

  scenario "editing an admin's name" do
    given_the_following_admin_exists(full_name: "Joey Joe", email: "joey-joe@shabadoo.org")
    visit(npq_separation_admin_admins_path)
    click_link("Add new admin")
    when_i_fill_in_the_new_admin_form_with(full_name: "New Joe", email: "joey-joe@shabadoo.org")
    click_button("Add admin")

    then_the_latest_admin_has_the_correct_details(full_name: "New Joe", email: "joey-joe@shabadoo.org")
  end

  scenario "adding a new admin with an email address of an archived admin" do
    given_the_following_super_admin_exists(full_name: "Super Admin", email: "superadmin@example.com", archived_at: 1.day.ago)
    visit(npq_separation_admin_admins_path)
    click_link("Add new admin")
    when_i_fill_in_the_new_admin_form_with(full_name: "Was a Super Admin", email: "superadmin@example.com")

    click_button("Add admin")

    then_the_latest_admin_has_the_correct_details(full_name: "Was a Super Admin", email: "superadmin@example.com", super_admin: false, archived_at: nil)
  end

  scenario "deleting an admin" do
    given_the_following_admin_exists(email: "tobedeleted@example.com", full_name: "Person who shall be deleted")
    and_i_am_on_the_admin_index

    when_i_click_the_delete_link_for(full_name: "Person who shall be deleted")

    then_the_admin_record_should_have_been_archived_for(email: "tobedeleted@example.com", full_name: "Person who shall be deleted")
  end

  scenario "listing admins" do
    given_the_following_super_admin_exists(full_name: "Super Admin", email: "superadmin@example.com", archived_at: 1.day.ago)
    and_i_am_on_the_admin_index
    then_i_should_see_the_super_admin(full_name: super_admin.full_name, email: super_admin.email)
    and_i_should_not_see_the_super_admin(full_name: "Super Admin", email: "superadmin@example.com")
  end

  def given_i_am_on_the_admin_index
    visit("/npq-separation/admin/admins")
  end
  alias_method :and_i_am_on_the_admin_index, :given_i_am_on_the_admin_index

  def given_the_following_admin_exists(**kwargs)
    FactoryBot.create(:admin, **kwargs)
  end

  def given_the_following_super_admin_exists(**kwargs)
    FactoryBot.create(:super_admin, **kwargs)
  end

  def and_i_should_be_on_the_add_new_admin_page
    expect(page).to have_current_path("/npq-separation/admin/admins/new")
  end

  def then_the_latest_admin_has_the_correct_details(full_name:, email:, super_admin: false, archived_at: nil)
    Admin.last.tap do |admin|
      expect(admin.full_name).to eql(full_name)
      expect(admin.email).to eql(email)
      expect(admin.super_admin).to eq(super_admin)
      expect(admin.archived_at).to eq(archived_at)
    end
  end

  def when_i_fill_in_the_new_admin_form_with(full_name:, email:)
    fill_in("Full name", with: full_name)
    fill_in("Email address", with: email)
  end

  def and_i_select_them_from_the_list_of_admins(email:)
    click_link(email)
  end

  def when_i_change_their_full_name_to(full_name)
    fill_in("Full name", with: full_name)
  end

  def when_i_change_their_email_to(email)
    fill_in("Email address", with: email)
  end

  def when_i_click_the_delete_link_for(full_name:)
    row = page.find(:xpath, "//td[text()='#{full_name}']/..")

    row.find("a", text: "Delete").click
  end

  def then_the_admin_record_should_have_been_archived_for(email:, full_name:)
    expect(page).to have_current_path("/npq-separation/admin/admins")
    expect(page).to have_content("#{full_name} deleted")
    expect(Admin.find_by(email:).archived_at).to be_present
  end

  def then_i_should_see_the_super_admin(full_name:, email:)
    expect(page).to have_content("#{full_name}#{email}Super Admin")
  end

  def and_i_should_not_see_the_super_admin(full_name:, email:)
    expect(page).not_to have_content("#{full_name}#{email}")
  end
end
