require "rails_helper"

RSpec.describe Cohorts::ExtendStatements, type: :model do
  subject(:service) { described_class.new(cohort:, extension_date:) }

  let(:cohort) { nil }
  let(:extension_date) { nil }

  describe "attributes" do
    it { is_expected.to respond_to :cohort }
    it { is_expected.to respond_to :extension_date }
  end

  describe "validations" do
    let(:cohort) { create(:cohort, :current, :with_statement) }
    let(:extension_date) { 2.years.from_now }

    it { is_expected.to validate_presence_of :cohort }
    it { is_expected.to validate_presence_of(:extension_date).with_message("Enter a date to extend statements to") }

    context "without existing statements" do
      let(:cohort) { create(:cohort, :current) }

      it { is_expected.to have_error :extension_date, :no_existing_statements, "There are no existing statements to copy for this Cohort" }
    end

    context "with a past date" do
      let(:extension_date) { Time.zone.today }

      it { is_expected.to have_error :extension_date, :in_past, "The date to extend statements forward to must be in the future" }
    end

    context "with an extension date before the last statements date" do
      let(:extension_date) { cohort.statements.last.payment_date - 1.month }

      it { is_expected.to have_error :extension_date, :before_last_statement, "The date to extend statements forward to must be after the Cohorts last statement" }
    end

    context "with extension date and cohort" do
      subject { described_class.new(cohort:, extension_date:) }

      it { is_expected.to be_valid }
    end
  end

  describe "statement methods" do
    let(:cohort) { create(:cohort, :current) }
    let(:lead_providers) { create_list(:lead_provider, 3) }

    let :statements do
      lead_providers.flat_map do |lead_provider|
        (1..3).to_a.reverse.map do
          create(:statement, cohort:, lead_provider:, for_date: it.months.from_now)
        end
      end
    end

    describe "#last_statement" do
      it { is_expected.to have_attributes last_statement: statements[6] }
    end

    describe "#ending_statements" do
      subject(:ending_statements) { service.ending_statements }

      before { statements }

      it "identifies the correct statements" do
        expect(ending_statements.values).to contain_exactly(statements[0], statements[3], statements[6])
      end

      it "orders by lead provider names" do
        expect(ending_statements.keys).to eq lead_providers.sort_by(&:name)
      end
    end
  end

  describe "#schedule_change" do
    subject(:schedule) { service.schedule_change }

    before { allow(Cohorts::ExtendStatementsJob).to receive(:perform_later) }

    context "with valid change" do
      let(:cohort) { create(:cohort, :current, :with_statement) }
      let(:extension_date) { 3.months.from_now.to_date }

      it "schedules the job" do
        expect(schedule).to be true

        expect(Cohorts::ExtendStatementsJob)
          .to have_received(:perform_later).with(cohort_id: cohort.id, extension_date:)
      end
    end

    context "with invalid change" do
      it "does not schedule the job" do
        expect(schedule).to be false

        expect(Cohorts::ExtendStatementsJob).not_to have_received(:perform_later)
      end
    end
  end

  describe "#extend_statements!" do
    pending "implementation"
  end
end
