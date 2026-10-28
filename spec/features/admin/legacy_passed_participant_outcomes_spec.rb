require "rails_helper"

RSpec.feature "Viewing Legacy passed participant outcomes", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:trn_for_historic_user) { "1234567" }
  let(:trn_for_user) { "0000001" }
  let(:user) { create(:user, :with_verified_trn, trn: trn_for_user) }
  let(:user_with_unverified_trn) { create(:user, trn: "0000002", trn_verified: false) }
  let(:course) { create(:course, :leading_teaching_development) }

  let(:legacy_passed_participant_outcome_no_user) do
    create(:legacy_passed_participant_outcome,
           trn: trn_for_historic_user,
           course_short_code: course.short_code,
           completion_date: Date.parse("2020-01-01"))
  end

  let(:legacy_passed_participant_outcome_no_user_legacy_course) do
    create(:legacy_passed_participant_outcome,
           trn: trn_for_historic_user,
           course_short_code: "NPQML",
           completion_date: Date.parse("2020-02-02"))
  end

  let(:legacy_passed_participant_outcome_with_user) do
    create(:legacy_passed_participant_outcome,
           trn: trn_for_user,
           course_short_code: course.short_code,
           completion_date: Date.parse("2020-03-03"))
  end

  let(:legacy_passed_participant_outcome_with_user_legacy_course) do
    create(:legacy_passed_participant_outcome,
           trn: trn_for_user,
           course_short_code: "NPQML",
           completion_date: Date.parse("2020-04-04"))
  end

  let(:legacy_passed_participant_outcome_with_unverified_trn_user) do
    create(:legacy_passed_participant_outcome,
           trn: user_with_unverified_trn.trn,
           course_short_code: course.short_code,
           completion_date: Date.parse("2020-03-03"))
  end

  before do
    user
    legacy_passed_participant_outcome_no_user
    legacy_passed_participant_outcome_no_user_legacy_course
    legacy_passed_participant_outcome_with_user
    legacy_passed_participant_outcome_with_user_legacy_course
    legacy_passed_participant_outcome_with_unverified_trn_user
    sign_in_as(create(:admin))
    visit(admin_users_path)
  end

  scenario "viewing legacy passed participant outcomes that have no user" do
    fill_in("Find a user", with: trn_for_historic_user)
    click_button("Search")

    expect(page).to have_content(trn_for_historic_user)
    click_link("Historic outcome", href: legacy_passed_participant_outcome_show_admin_users_path(legacy_passed_participant_outcome_no_user))

    expect(page).to have_css("h1", text: "Historic outcome for TRN: #{trn_for_historic_user}")
    expect(page).to have_summary_item("Course", course.name)
    expect(page).to have_summary_item("TRN", trn_for_historic_user)
    expect(page).to have_summary_item("Completion date", legacy_passed_participant_outcome_no_user.completion_date.to_formatted_s(:govuk))

    click_link("Back")
    click_link("Historic outcome", href: legacy_passed_participant_outcome_show_admin_users_path(legacy_passed_participant_outcome_no_user_legacy_course))
    expect(page).to have_summary_item("Course", legacy_passed_participant_outcome_no_user_legacy_course.course_short_code)
    expect(page).to have_summary_item("TRN", trn_for_historic_user)
    expect(page).to have_summary_item("Completion date", legacy_passed_participant_outcome_no_user_legacy_course.completion_date.to_formatted_s(:govuk))
  end

  scenario "viewing legacy passed participant outcomes that have a user" do
    fill_in("Find a user", with: trn_for_user)
    click_button("Search")

    expect(page).to have_content(trn_for_user)
    expect(page).not_to have_content("Historic outcome")
    click_link(user.full_name)

    expect(page).to have_css("h2", text: "Legacy outcomes")

    summary_cards = all(".govuk-summary-card")

    within(summary_cards[1]) do
      expect(page).to have_summary_item("Course", course.name)
      expect(page).to have_summary_item("TRN", trn_for_user)
      expect(page).to have_summary_item("Completion date", legacy_passed_participant_outcome_with_user.completion_date.to_formatted_s(:govuk))
    end

    within(summary_cards[2]) do
      expect(page).to have_summary_item("Course", legacy_passed_participant_outcome_with_user_legacy_course.course_short_code)
      expect(page).to have_summary_item("TRN", trn_for_user)
      expect(page).to have_summary_item("Completion date", legacy_passed_participant_outcome_with_user_legacy_course.completion_date.to_formatted_s(:govuk))
    end
  end

  scenario "viewing legacy passed participant outcomes that have a user but their TRN is not verified" do
    fill_in("Find a user", with: user_with_unverified_trn.trn)
    click_button("Search")

    expect(page).to have_content(user_with_unverified_trn.trn)
    click_link(user_with_unverified_trn.full_name)

    expect(page).not_to have_css("h2", text: "Legacy outcomes")
  end
end
