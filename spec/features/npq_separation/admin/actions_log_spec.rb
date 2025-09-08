require "rails_helper"

RSpec.feature "actions log", :no_js, :versioning, type: :feature do
  include Helpers::AdminLogin

  let(:application_1) { create(:application) }
  let(:application_2) { create(:application) }
  let(:sign_in_as_admin) { create(:admin) }
  let(:admin) { create(:admin) }

  before do
    admin
    application_1
    application_2
    PaperTrail.request.whodunnit = "Admin #{admin.id}"

    Applications::ChangeFundingEligibility.new(
      application: application_1,
      eligible_for_funding: true,
    ).change_funding_eligibility

    Applications::ChangeFundingEligibility.new(
      application: application_2,
      eligible_for_funding: true,
    ).change_funding_eligibility

    Applications::ChangeFundingEligibility.new(
      application: application_1,
      eligible_for_funding: false,
    ).change_funding_eligibility

    sign_in_as(create(:admin))
  end

  scenario "Admin actions log page" do
    click_on "Actions log"
    all_admin_users = Admin.order(:full_name).map { |a| "#{a.full_name} (#{a.email})" }
    expect(page).to have_select("Admin user", options: ["- select admin user -"] + all_admin_users)
  end

  scenario "viewing an admin user's actions" do
    visit npq_separation_admin_actions_log_path
    click_on "Continue"

    expect(page).to have_current_path(npq_separation_admin_actions_log_path)

    select "#{admin.full_name} (#{admin.email})", from: "Admin user"
    click_on "Continue"

    expect(page).to have_table rows: [
      [application_1.ecf_id, application_1.versions.last.created_at.to_fs(:govuk_short), "eligible_for_funding, funding_eligiblity_status_code", "History"],
      [application_2.ecf_id, application_2.updated_at.to_fs(:govuk_short), "eligible_for_funding, funding_eligiblity_status_code", "History"],
      [application_1.ecf_id, application_1.versions.first.created_at.to_fs(:govuk_short), "eligible_for_funding, funding_eligiblity_status_code", "History"],
    ]
    expect(page).to have_link("History", href: npq_separation_admin_applications_history_path(application_1))
    expect(page).to have_link("History", href: npq_separation_admin_applications_history_path(application_2))
  end

  scenario "when there are no actions for an admin user" do
    visit npq_separation_admin_actions_log_admin_user_path(sign_in_as_admin.id)
    expect(page).to have_content "No applications have been updated by this admin user."
  end
end
