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

  scenario "viewing an application with outcomes" do
    visit(npq_separation_admin_applications_path)

    application = Application.order(created_at: :asc, id: :asc).first
    started_declaration = create(:declaration, :started, application:)
    completed_declaration = create(:declaration, :completed, application:)

    outcome = create(:participant_outcome, :passed, declaration: completed_declaration)

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
    visit(npq_separation_admin_applications_path)
    application = Application.order(created_at: :asc, id: :asc).first

    within("tr", text: application.user.full_name) do
      click_link("View")
    end

    click_link("Course outcome")
    expect(page).to have_text("There are no outcomes for this application yet")
  end
end
