require "rails_helper"

RSpec.describe Milestones::Create, :with_default_schedules, type: :model do
  subject(:service) { described_class.new(schedule_id: schedule.id, declaration_type:, statement_date: statement_date_param) }

  let(:cohort) { Cohort.last }
  let(:schedule) { cohort.schedules.first }
  let(:declaration_type) { "started" }
  let(:statement_month) { 5 }
  let(:statement_date_param) { Date.new(cohort.start_year, statement_month).to_s }

  describe "validations" do
    it { is_expected.to validate_presence_of(:schedule_id) }
    it { is_expected.to validate_presence_of(:declaration_type).with_message("Please choose a declaration type") }
    it { is_expected.to validate_presence_of(:statement_date).with_message("Please choose a statement date") }
  end

  describe "#create!" do
    subject(:create_milestone) { service.create! }

    before do
      LeadProvider.find_each do |lead_provider|
        create(:statement, lead_provider:, cohort: Cohort.first, year: cohort.start_year, month: statement_month, output_fee: true)
        create(:statement, lead_provider:, cohort:, year: cohort.start_year, month: statement_month, output_fee: true)
      end
    end

    it "creates a milestone with the given attributes" do
      subject
      expect(Milestone.exists?(schedule_id: schedule.id, declaration_type:)).to be true
    end

    it "creates milestone statements for every lead provider for the given statement date" do
      subject
      expect(MilestoneStatement.count).to eq(LeadProvider.count)

      LeadProvider.find_each do |lead_provider|
        statement = lead_provider.statements.find_by(month: statement_month, year: cohort.start_year, cohort: schedule.cohort)
        milestone = Milestone.find_by(schedule_id: schedule.id, declaration_type:)
        expect(MilestoneStatement.exists?(milestone:, statement:)).to be true
      end
    end

    context "when there aren't statements for the schedule's cohort for all lead providers" do
      let(:cohort_with_missing_statements) { Cohort.left_joins(:statements).select("cohorts.*, count(statements.id) as statements_count").group("cohorts.id").having("count(statements.id) = 0").first }
      let(:schedule) { cohort_with_missing_statements.schedules.first }
      let(:statement_date_param) { Date.new(cohort_with_missing_statements.start_year, statement_month).to_s }
      let(:statement) { create(:statement, lead_provider: LeadProvider.last, cohort: cohort_with_missing_statements, year: cohort_with_missing_statements.start_year, month: statement_month, output_fee: true) }

      before { statement }

      it "creates milestone statements for the statements that do exist" do
        subject
        milestone = Milestone.find_by(schedule_id: schedule.id, declaration_type:)
        expect(MilestoneStatement.exists?(milestone:, statement:)).to be true
      end
    end
  end
end
