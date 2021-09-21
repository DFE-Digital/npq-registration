require "rails_helper"

RSpec.feature "admin", type: :feature do
  let(:admin) { create(:admin) }

  scenario "when logged in, it shows admin homepage" do
    visit "/admin"
    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/sign-in")

    page.fill_in "Email address", with: admin.email
    page.click_button "Sign in"
    expect(page.current_path).to eql("/session/sign-in-code")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"
    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")

    applications = create_list :application, 2

    page.click_link("Applications")
    expect(page.current_path).to eql("/admin/applications")

    applications.each do |app|
      expect(page).to have_content(app.user.email)
    end
  end
end
