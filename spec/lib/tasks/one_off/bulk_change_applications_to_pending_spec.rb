require "rails_helper"

Rails.application.load_tasks

RSpec.describe "one_off:bulk_change_to_pending" do
  let(:csv_file) { Tempfile.new }
  let(:csv_file_path) { csv_file.path }

  before do
    create(:application, :accepted)
    create(:application, :accepted)
    csv_file.write(Application.all.pluck(:ecf_id).join("\n"))
    csv_file.rewind
  end

  after do
    Rake::Task["one_off:bulk_change_to_pending"].reenable
  end

  context "when dry run not specified" do
    subject(:run_task) { Rake::Task["one_off:bulk_change_to_pending"].invoke(csv_file_path) }

    it "does not update any applications" do
      run_task
      expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[accepted accepted]
    end
  end

  context "when dry run true" do
    subject(:run_task) { Rake::Task["one_off:bulk_change_to_pending"].invoke(csv_file_path, "true") }

    it "does not update any applications" do
      run_task
      expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[accepted accepted]
    end
  end

  context "when dry run false" do
    subject(:run_task) { Rake::Task["one_off:bulk_change_to_pending"].invoke(csv_file_path, "false") }

    it "updates applications to pending" do
      run_task
      expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[pending pending]
    end
  end

  context "when the CSV file is not found" do
    subject(:run_task) { Rake::Task["one_off:bulk_change_to_pending"].execute(file: "nonexistent_file") }

    it "exits with error code 1" do
      expect { run_task }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end
  end
end
