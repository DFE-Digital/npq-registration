require "rails_helper"

RSpec.feature "Milestones", :no_js, :with_default_schedules do
  include Helpers::AdminLogin

  let(:cohort) { Cohort.last }
  let(:schedule) { cohort.schedules.first }
  let(:statement) { Statement.first }

  before do
    LeadProvider.find_each do |lead_provider|
      create(:statement, lead_provider:, cohort:, year: 2022, month: 5)
    end
    sign_in_as(admin)
  end

  context "when logged in as a super admin" do
    let(:admin) { create :super_admin }
    let(:other_statement) { Statement.last }

    scenario "creating/editing/deleting a milestone" do
      visit npq_separation_admin_cohort_schedule_path(cohort, schedule)

      # creating a milestone
      click_link "Add milestone"
      choose "started", visible: false
      statement_date = Date.new(statement.year, statement.month)
      select statement_date.to_fs(:govuk_approx), from: "Select statement date to associate with milestone"

      click_button "Continue"

      LeadProvider.find_each do |lead_provider|
        statement = lead_provider.statements.find_by(month: statement_date.month, year: statement_date.year)
        expect(statement.milestones.where(declaration_type: "started").count).to eq 1 if statement
      end

      # editing a milestone
      click_link "Change statement date"
      statement_date = Date.new(other_statement.year, other_statement.month)
      select statement_date.to_fs(:govuk_approx), from: "Select statement date to associate with milestone"
      click_button "Continue"

      LeadProvider.find_each do |lead_provider|
        statement = lead_provider.statements.find_by(month: other_statement.month, year: other_statement.year)
        expect(statement.milestones.where(declaration_type: "started").count).to eq 1 if statement
      end

      # deleting a milestone
      click_link "Delete milestone"
      click_button "Confirm delete milestone"

      LeadProvider.find_each do |lead_provider|
        statement = lead_provider.statements.find_by(month: other_statement.month, year: other_statement.year)
        expect(statement.milestones.where(declaration_type: "started").count).to eq 0 if statement
      end
    end

    scenario "adding a milestone when all declaration types are taken" do
      create(:milestone, declaration_type: "started", schedule:)
      create(:milestone, declaration_type: "retained-1", schedule:)
      create(:milestone, declaration_type: "retained-2", schedule:)
      create(:milestone, declaration_type: "completed", schedule:)

      visit npq_separation_admin_cohort_schedule_path(cohort, schedule)
      click_link "Add milestone"

      expect(page).to have_content("Milestones for all declaration types have already been created.")
      expect(page).not_to have_button("Continue")
    end
  end

  context "when logged in as a normal admin" do
    let(:admin) { create :admin }

    before { create(:milestone, declaration_type: "started", schedule:) }

    scenario "should not be able to create/updated/delete milestones" do
      visit npq_separation_admin_cohort_schedule_path(cohort, schedule)

      expect(page).not_to have_button("Add milestone")
      expect(page).not_to have_link("Change statement date")
      expect(page).not_to have_link("Delete milestone")
    end
  end
end
