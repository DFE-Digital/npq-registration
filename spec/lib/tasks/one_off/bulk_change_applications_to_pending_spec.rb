require "rails_helper"

Rails.application.load_tasks

RSpec.describe "one_off:bulk_change_to_pending" do
  let(:csv_file) { Tempfile.new }

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
    subject { Rake::Task["one_off:bulk_change_to_pending"].invoke(csv_file.path) }

    it "does not update any applications" do
      subject
      expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[accepted accepted]
    end
  end

  context "when dry run true" do
    subject { Rake::Task["one_off:bulk_change_to_pending"].invoke(csv_file.path, "true") }

    it "does not update any applications" do
      subject
      expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[accepted accepted]
    end
  end

  context "when dry run false" do
    subject { Rake::Task["one_off:bulk_change_to_pending"].invoke(csv_file.path, "false") }

    it "updates applications to pending" do
      subject
      expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[pending pending]
    end
  end
end
