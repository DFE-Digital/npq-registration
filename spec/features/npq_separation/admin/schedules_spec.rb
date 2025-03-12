require "rails_helper"

RSpec.feature "Managing schedules", :ecf_api_disabled, type: :feature do
  include Helpers::AdminLogin

  let(:admin)  { create :admin }
  let(:cohort) { create :cohort, start_year: 2026 }

  let(:new_button_text) { "New schedule" }
  let(:edit_button_text) { "Edit schedule details" }
  let(:delete_button_text) { "Delete schedule" }

  let!(:schedules) do
    [
      create(:schedule, :npq_ehco_december, cohort:),
      create(:schedule, :npq_aso_december, cohort:, allowed_declaration_types: %w[started completed]),
    ]
  end

  before do
    sign_in_as admin
  end

  scenario "view the list of schedules for a cohort" do
    visit_cohort

    expect(page).to have_css("h2", text: "Schedules")
    expect(page).to have_table(rows: [
      [schedules[1].name, short_date(schedules[1].applies_from), short_date(schedules[1].applies_to), 2],
      [schedules[0].name, short_date(schedules[0].applies_from), short_date(schedules[0].applies_to), 4],
    ])
  end

  scenario "view schedule details" do
    schedule = schedules.last

    visit_cohort
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

  context "when logged in as a super admin" do
    let(:schedule) { schedules.first }
    let(:course_group) { CourseGroup.where.not(id: schedule.course_group_id).last }

    before do
      admin.update! super_admin: true
    end

    scenario "creation" do
      visit_cohort
      click_on new_button_text

      fill_in_schedule_form(course_group)

      expect { click_on "Create schedule" }.to change(Schedule, :count).by(1)

      schedule = Schedule.order(created_at: :desc, id: :desc).first
      expect(page).to have_text("Schedule created")
      expect_filled_in_schedule_attributes(schedule, course_group)
    end

    scenario "editing" do
      navigate_to_schedule
      click_on edit_button_text
      fill_in_schedule_form(course_group)

      expect { click_on "Update schedule" }.not_to(change(Schedule, :count))

      schedule.reload
      expect(page).to have_text("Schedule updated")
      expect_filled_in_schedule_attributes(schedule, course_group)
    end

    scenario "deletion" do
      navigate_to_schedule

      click_on delete_button_text
      expect { click_on "Confirm" }.to change(Schedule, :count).by(-1)
    end
  end

  context "when logged in as a normal admin" do
    let(:schedule) { schedules.first }

    scenario "cannot create" do
      visit_cohort
      expect(page).not_to have_link(new_button_text)
    end

    scenario "cannot edit" do
      navigate_to_schedule
      expect(page).not_to have_link(edit_button_text)
    end

    scenario "cannot delete" do
      navigate_to_schedule
      expect(page).not_to have_link(delete_button_text)
    end
  end

private

  def visit_cohort
    visit npq_separation_admin_cohort_path(cohort)
  end

  def navigate_to_schedule
    visit_cohort
    click_on schedule.name
  end

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
