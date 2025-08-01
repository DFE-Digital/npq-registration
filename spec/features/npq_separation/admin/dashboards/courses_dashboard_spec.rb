require "rails_helper"

RSpec.feature "Viewing the courses dashboard", type: :feature do
  include Helpers::AdminLogin

  let(:test_course) { create(:course, name: "Test Course") }
  let(:current_cohort) { create(:cohort, :current) }
  let(:previous_cohort) { create(:cohort, :previous) }

  before do
    sign_in_as(create(:admin))

    create_list(:application, 2, course: test_course, cohort: current_cohort)
    create(:application, course: test_course, cohort: previous_cohort)
  end

  scenario "viewing the courses dashboard table" do
    visit(npq_separation_admin_dashboard_path("courses-dashboard"))

    expect(page).to have_css("h1", text: "Courses dashboard")
    expect(page).to have_css("th", text: "Course")
    expect(page).to have_css("th", text: "Applications")
    expect(page).to have_content("3")
  end

  scenario "filtering courses dashboard by a single cohort updates application counts" do
    visit npq_separation_admin_dashboard_path("courses-dashboard")

    select previous_cohort.start_year.to_s, from: "Search by cohort"
    click_button "Search"

    expect(page).to have_content("Test Course")
    expect(page).to have_content("1")
  end
end
