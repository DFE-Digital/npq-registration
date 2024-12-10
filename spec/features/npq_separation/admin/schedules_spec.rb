require "rails_helper"

RSpec.feature "Managing schedules", :ecf_api_disabled, type: :feature do
  include Helpers::AdminLogin

  let(:cohort) { create :cohort, start_year: 2026 }

  let!(:schedules) do
    [
      create(:schedule, :npq_ehco_december, cohort:),
      create(:schedule, :npq_aso_december, cohort:, allowed_declaration_types: %w[started completed]),
    ]
  end

  before do
    sign_in_as create(:admin)
    visit npq_separation_admin_cohort_path(cohort)
  end

  scenario "viewing the list of schedules for a cohort" do
    expect(page).to have_css("h2", text: "Schedules")
    expect(page).to have_table(rows: [
      [schedules[1].name, short_date(schedules[1].applies_from), short_date(schedules[1].applies_to), 2],
      [schedules[0].name, short_date(schedules[0].applies_from), short_date(schedules[0].applies_to), 4],
    ])
  end

  scenario "viewing schedule details" do
    schedule = schedules.last
    click_on schedule.name

    within(".govuk-summary-list") do |sl|
      expect(sl).to have_summary_item("Cohort", "2026/27")
      expect(sl).to have_summary_item("Name", schedule.name)
      expect(sl).to have_summary_item("Identifier", schedule.identifier)
      expect(sl).to have_summary_item("Course group", schedule.course_group.name)
      expect(sl).to have_summary_item("Applies from", long_date(schedule.applies_from))
      expect(sl).to have_summary_item("Applies to", long_date(schedule.applies_to))
      expect(sl).to have_summary_item("Declaration types", "started, completed")
    end
  end

  scenario "creating a new schedule" do
    course_group = CourseGroup.last

    click_on "New schedule"

    fill_in_schedule_form(course_group)

    # TODO: rename this button
    expect { click_on "Save" }.to change(Schedule, :count).by(1)

    schedule = Schedule.order(created_at: :desc).first
    expect(page).to have_text("Schedule #{schedule.name} created")
    expect_filled_in_schedule_attributes(schedule, course_group)
  end

  scenario "editing a schedule" do
    schedule = schedules.first
    course_group = CourseGroup.where.not(id: schedule.course_group_id).last

    click_on schedule.name
    click_on "Edit schedule"
    fill_in_schedule_form(course_group)
    # TODO: rename this button
    expect { click_on "Save" }.not_to(change(Schedule, :count))

    schedule.reload
    expect(page).to have_text("Schedule #{schedule.name} updated")
    expect_filled_in_schedule_attributes(schedule, course_group)
  end

  scenario "destroying a cohort" do
    pending "Not yet implemented"
    fail
  end

private

  def fill_in_schedule_form(course_group)
    fill_in "Name", with: "name"
    fill_in "Identifier", with: "identifier"
    select course_group.name, from: "Course group"

    fieldsets = all("fieldset")

    within(fieldsets[0]) do
      fill_in "Day", with: "1"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2026"
    end

    within(fieldsets[1]) do
      fill_in "Day", with: "3"
      fill_in "Month", with: "4"
      fill_in "Year", with: "2026"
    end

    uncheck "retained-2", visible: :all
  end

  def expect_filled_in_schedule_attributes(schedule, course_group)
    expect(schedule.name).to eq("name")
    expect(schedule.identifier).to eq("identifier")
    expect(schedule.course_group).to eq(course_group)
    expect(schedule.applies_from).to eq(Date.new(2026, 2, 1))
    expect(schedule.applies_to).to eq(Date.new(2026, 4, 3))
    expect(schedule.allowed_declaration_types).to eq(%w[started retained-1 completed])
  end

  def short_date(date)
    date.to_date.to_fs(:govuk_short)
  end

  def long_date(date)
    date.to_date.to_fs(:govuk)
  end
end
