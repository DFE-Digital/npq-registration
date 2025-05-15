require "rails_helper"

RSpec.feature "Listing and viewing schools", type: :feature do
  include Helpers::AdminLogin

  let(:schools_per_page) { Pagy::DEFAULT[:limit] }

  before do
    sign_in_as(create(:admin))
  end

  context "when viewing all schools" do
    before do
      create_list(:school, schools_per_page + 1, :with_address, la_name: "Barnet")
      visit(npq_separation_admin_schools_path)
    end

    scenario "viewing the list of schools" do
      expect(page).to have_css("h1", text: "Workplaces")

      School.order(name: :asc).limit(schools_per_page).each do |school|
        expect(page).to have_text(school.name)
      end

      expect(page).to have_css(".govuk-pagination__item--current", text: 1)
    end

    scenario "navigating to the second page of schools" do
      click_on("Next")

      expect(page).to have_css("table.govuk-table tbody tr", count: 1)
      expect(page).to have_css(".govuk-pagination__item--current", text: "2")
    end

    scenario "viewing school details" do
      school = School.order(name: :asc).first

      within first('tbody tr.govuk-table__row') do |row|
        expect(find('td:nth-child(1)').text).to eq(school.name)
        expect(find('td:nth-child(2)').text).to eq(school.id.to_s)
        expect(find('td:nth-child(3)').text).to eq(school.urn)
        expect(find('td:nth-child(4)').text).to eq(school.ukprn)
        expect(find('td:nth-child(5)').text).to eq(school.la_name)
        expect(find('td:nth-child(6)').text).to match(school.postcode)
      end
    end
  end

  context "when searching for workplace" do
    let(:school_name) { "School 1" }
    let(:school_urn)  {  "123" }

    let(:school) { create(:school, :with_address,  name: school_name, urn: school_urn) }

    before do
      create(:school,  name: "School 2", urn: "124")
      visit(npq_separation_admin_schools_path)
    end

    scenario "searching using urn" do
      fill_in("Find a workplace", with: school.name)
      click_button("Search")

      expect(page).to have_css('tbody tr.govuk-table__row', count: 1)

      within first('tbody tr.govuk-table__row') do |row|
        expect(find('td:nth-child(1)').text).to eq(school.name)
      end
    end

    scenario "searching using name" do
      fill_in("Find a workplace", with: school.urn)
      click_button("Search")

      expect(page).to have_css('tbody tr.govuk-table__row', count: 1)

      within first('tbody tr.govuk-table__row') do |row|
        expect(find('td:nth-child(1)').text).to eq(school.name)
      end
    end
  end
end
