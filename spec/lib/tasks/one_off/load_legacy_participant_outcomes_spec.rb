require "rails_helper"

Rails.application.load_tasks

RSpec.describe "one_off:legacy_participant_outcomes:import" do
  let(:csv_file) { Tempfile.new }
  let(:csv_file_path) { csv_file.path }

  before do
    csv_file.write("trn,npq_type,awarded_date\n")
    csv_file.write("1000002,389040005,11/13/2017\n")
    csv_file.write("1000003,389040005,07/31/2018\n")
    csv_file.rewind
    create(:legacy_passed_participant_outcome, trn: "1000000")
    create(:legacy_passed_participant_outcome, trn: "1000001")
    allow(Logger).to receive(:new) { instance_double(Logger, info: nil, error: nil) }
  end

  after do
    Rake::Task["one_off:legacy_participant_outcomes:import"].reenable
  end

  context "when dry run not specified" do
    subject(:run_task) { Rake::Task["one_off:legacy_participant_outcomes:import"].invoke(csv_file_path) }

    it "does not delete or create any LegacyPassedParticipantOutcomes" do
      run_task
      expect(LegacyPassedParticipantOutcome.all.pluck(:trn)).to eq %w[1000000 1000001]
    end
  end

  context "when dry run true" do
    subject(:run_task) { Rake::Task["one_off:legacy_participant_outcomes:import"].invoke(csv_file_path, "true") }

    it "does not delete or create any LegacyPassedParticipantOutcomes" do
      run_task
      expect(LegacyPassedParticipantOutcome.all.pluck(:trn)).to eq %w[1000000 1000001]
    end
  end

  context "when dry run false" do
    subject(:run_task) { Rake::Task["one_off:legacy_participant_outcomes:import"].invoke(csv_file_path, "false") }

    it "creates new LegacyPassedParticipantOutcomes" do
      run_task
      expect(LegacyPassedParticipantOutcome.all.pluck(:trn)).to eq %w[1000002 1000003]
    end
  end

  context "when the CSV file is not found" do
    subject(:run_task) { Rake::Task["one_off:legacy_participant_outcomes:import"].execute(file_path: "nonexistent_file") }

    it_behaves_like "exiting with error code 1"
  end
end
