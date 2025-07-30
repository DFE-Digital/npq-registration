require "rails_helper"

RSpec.feature "Viewing the courses dashboard", type: :feature do
  include Helpers::AdminLogin

  before do
    create :cohort, :current
    sign_in_as(create(:admin))
  end

  scenario "viewing the courses dashboard table" do
    visit(npq_separation_admin_dashboard_path("courses-dashboard"))

    expect(page).to have_css("h1", text: "Courses dashboard")
    expect(page).to have_css("th", text: "Course")
    expect(page).to have_css("th", text: "Applications")
  end

  scenario "filtering courses dashboard by a single cohort" do
    test_course = create(:course, name: "Filtered Course")
    create(:application, course: test_course, cohort: Cohort.current)

    visit npq_separation_admin_dashboard_path("courses-dashboard")

    select Cohort.current.start_year.to_s, from: "Search by cohort"
    click_button "Search"

    expect(page).to have_content("Filtered Course")
  end
end
