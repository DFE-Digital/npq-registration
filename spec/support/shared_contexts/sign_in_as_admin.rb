RSpec.shared_context("sign in as admin") do
  before do
    visit "/admin"
    expect(page.current_path).to eql("/sign-in")

    page.fill_in "What's your email address?", with: admin.email
    page.click_button "Sign in"
    expect(page.current_path).to eql("/session/sign-in-code")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"
    expect(page.current_path).to eql("/account")

    page.click_link("Admin")
    expect(page.current_path).to eql("/admin")
  end
end
