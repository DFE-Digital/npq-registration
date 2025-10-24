require "rails_helper"

RSpec.feature "Administering Glossary", type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }
  let(:super_admin) { create(:super_admin) }

  scenario "regular admin can view the Glossary page and navigate by letter" do
    sign_in_as_admin
    visit "/npq-separation/admin"

    click_link "Glossary"
    expect(page).to have_current_path("/npq-separation/admin/glossary")
    expect(page).to have_css("h1.govuk-heading-l", text: "Glossary")

    expect(page).to have_link("A", href: "#A")
    expect(page).to have_link("C", href: "#C")

    click_link "A"
    expect(page).to have_css("h2#A", text: "A")
    expect(page).to have_content("Application")
  end

  scenario "super admin can view the Glossary page and navigate by letter" do
    sign_in_as_super_admin
    visit "/npq-separation/admin"

    click_link "Glossary"
    expect(page).to have_current_path("/npq-separation/admin/glossary")
    expect(page).to have_css("h1.govuk-heading-l", text: "Glossary")

    expect(page).to have_link("A", href: "#A")
    expect(page).to have_link("C", href: "#C")

    click_link "A"
    expect(page).to have_css("h2#A", text: "A")
    expect(page).to have_content("Application")
  end
end
