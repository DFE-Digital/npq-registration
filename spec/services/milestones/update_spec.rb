require "rails_helper"

RSpec.describe Milestones::Update, :with_default_schedules, type: :model do
  subject(:service) { described_class.new(milestone_id: milestone.id, statement_date: statement_date_param) }

  let(:cohort) { Cohort.last }
  let(:schedule) { cohort.schedules.first }
  let(:declaration_type) { "started" }
  let(:milestone) { create(:milestone, schedule:, declaration_type:) }
  let(:statement_date_param) { Date.new(cohort.start_year, new_statement_month).to_s }
  let(:statement_month) { 5 }
  let(:new_statement_month) { 12 }

  let(:milestone_statements) do
    LeadProvider.find_each do |lead_provider|
      statement = lead_provider.statements.with_output_fee.find_by(month: statement_month, year: cohort.start_year)
      milestone = Milestone.find_by(schedule_id: schedule.id, declaration_type:)
      create(:milestone_statement, milestone:, statement:)
    end
  end

  before do
    milestone
    LeadProvider.find_each do |lead_provider|
      create(:statement, lead_provider:, cohort: Cohort.first, year: cohort.start_year, month: new_statement_month, output_fee: true)
      create(:statement, lead_provider:, cohort: Cohort.first, year: cohort.start_year, month: statement_month, output_fee: true)
      create(:statement, lead_provider:, cohort:, year: cohort.start_year, month: statement_month, output_fee: true)
      create(:statement, lead_provider:, cohort:, year: cohort.start_year, month: new_statement_month, output_fee: true)
    end
    milestone_statements
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:milestone_id) }
    it { is_expected.to validate_presence_of(:statement_date).with_message("Please choose a statement date") }
  end

  describe "#update!" do
    subject(:update_milestone) { service.update! }

    it "replaces milestone statements with those for the new statement date" do
      subject

      expect(MilestoneStatement.count).to eq(LeadProvider.count)

      LeadProvider.find_each do |lead_provider|
        statement = lead_provider.statements.find_by(month: new_statement_month, year: cohort.start_year, cohort:)
        milestone = Milestone.find_by(schedule_id: schedule.id, declaration_type:)
        expect(MilestoneStatement.exists?(milestone:, statement:)).to be true
      end
    end

    context "when there aren't statements for the given date"
  end
end
