require "rails_helper"

RSpec.feature "Viewing participant outcomes", type: :feature do
  include Helpers::AdminLogin

  before do
    sign_in_as(create(:admin))
  end

  scenario "viewing an application with outcomes" do
    application = create(:application)

    # The declaration is started by default (declaration_type: "started")
    started_declaration   = create(:declaration, application: application)
    completed_declaration = create(:declaration, :completed, application: application)
    outcome               = create(:participant_outcome, :passed, declaration: completed_declaration)

    visit(npq_separation_admin_applications_path)

    within("tr", text: application.user.full_name) do
      click_link("View")
    end

    click_link("Course outcome")

    expect(page).to have_text("Passed")
    expect(page).to have_text(started_declaration.declaration_date.to_date.to_fs(:govuk_short))
    expect(page).to have_text(outcome.completion_date.to_fs(:govuk_short))
    expect(page).to have_text(outcome.created_at.to_date.to_fs(:govuk_short))
  end

  scenario "viewing an application without outcomes" do
    application = create(:application)

    visit(npq_separation_admin_applications_path)

    within("tr", text: application.user.full_name) do
      click_link("View")
    end

    click_link("Course outcome")

    expect(page).to have_text("There are no outcomes for this application yet")
  end
end
