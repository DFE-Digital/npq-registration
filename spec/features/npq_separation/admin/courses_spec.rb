require "rails_helper"

RSpec.feature "Listing and viewing courses", type: :feature do
  include Helpers::AdminLogin

  let(:courses_per_page) { Pagy::DEFAULT[:items] }

  before do
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of courses" do
    visit(npq_separation_admin_courses_path)

    expect(page).to have_css("h1", text: "All courses")

    Course.order(name: :asc).limit(courses_per_page).each do |course|
      expect(page).to have_link(course.name, href: npq_separation_admin_course_path(course))
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of courses" do
    visit(npq_separation_admin_courses_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 5)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "viewing course details" do
    visit(npq_separation_admin_courses_path)

    course = Course.order(name: :asc).first

    click_link(course.name)

    expect(page).to have_css("h1", text: course.name)

    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("ID", course.id)
      expect(summary_list).to have_summary_item("ECF ID", course.ecf_id)
      expect(summary_list).to have_summary_item("Identifier", course.identifier)
      expect(summary_list).to have_summary_item("Position", course.position)
      expect(summary_list).to have_summary_item("Description", course.description)
      expect(summary_list).to have_summary_item("Display", "No")
    end
  end
end
