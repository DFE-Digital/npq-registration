require "rails_helper"

RSpec.describe Milestones::Destroy, :with_default_schedules, type: :model do
  subject(:service) { described_class.new(milestone_id: milestone.id) }

  let(:cohort) { Cohort.last }
  let(:schedule) { cohort.schedules.first }
  let(:declaration_type) { "started" }
  let(:milestone) { create(:milestone, schedule:, declaration_type:) }
  let(:statement_month) { 5 }

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
      create(:statement, lead_provider:, cohort:, year: cohort.start_year, month: statement_month, output_fee: true)
    end
    milestone_statements
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:milestone_id) }
  end

  describe "#destroy!" do
    subject(:destroy_milestone) { service.destroy! }

    it "deletes the milestone and its associated milestone statements" do
      subject

      expect(Milestone.count).to eq 0
      expect(MilestoneStatement.count).to eq 0
    end
  end
end
