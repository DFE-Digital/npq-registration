require "rails_helper"

RSpec.feature "Viewing participant outcomes", type: :feature do
  include Helpers::AdminLogin
  include Helpers::MailHelper

  let(:applications_per_page) { Pagy::DEFAULT[:limit] }
  let(:applications_in_order) { Application.order(created_at: :asc, id: :asc) }

  before do
    create_list(:application, applications_per_page + 1)
    sign_in_as(create(:admin))
  end

  scenario "viewing application details with declarations" do
    visit(npq_separation_admin_applications_path)

    application = Application.order(created_at: :asc, id: :asc).first
    started_declaration = create(:declaration, :started, application:)
    completed_declaration = create(:declaration, :completed, application:)

    outcome = create(:participant_outcome, :passed, declaration: completed_declaration)

    # Navigate to application
    within("tr", text: application.user.full_name) do
      click_link("View")
    end

    # go to outcomes
    click_link("Course outcome")

    # check that the outcome is displayed
    expect(page).to have_text("Passed")
    expect(page).to have_text(started_declaration.declaration_date.to_date.to_fs(:govuk_short))
    expect(page).to have_text(outcome.completion_date.to_fs(:govuk_short))
    expect(page).to have_text(outcome.created_at.to_date.to_fs(:govuk_short))
  end
end
