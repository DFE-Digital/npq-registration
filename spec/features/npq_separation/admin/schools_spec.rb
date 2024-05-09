require "rails_helper"

RSpec.feature "Listing and viewing schools", type: :feature do
  include Helpers::AdminLogin

  let(:schools_per_page) { Pagy::DEFAULT[:items] }

  before do
    create_list(:school, schools_per_page + 1)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of schools" do
    visit(npq_separation_admin_schools_path)

    expect(page).to have_css("h1", text: "All schools")

    School.order(name: :asc).limit(schools_per_page).each do |school|
      expect(page).to have_link(school.name, href: npq_separation_admin_school_path(school))
      expect(page).to have_css("td", text: school.urn)
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of schools" do
    visit(npq_separation_admin_schools_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "viewing school details" do
    visit(npq_separation_admin_schools_path)

    school = School.order(name: :asc).first

    click_link(school.name)

    expect(page).to have_css("h1", text: school.name)

    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("ID", school.id)
      expect(summary_list).to have_summary_item("URN", school.urn)
      expect(summary_list).to have_summary_item("UKPRN", school.ukprn)
      expect(summary_list).to have_summary_item("Local authority", school.la_name)
      expect(summary_list).to have_summary_item("Address", school.address_1)
    end
  end
end
