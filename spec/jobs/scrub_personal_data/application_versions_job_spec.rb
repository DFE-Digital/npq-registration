require "rails_helper"

RSpec.describe ScrubPersonalData::ApplicationVersionsJob, type: :job do
  subject(:perform_job) { described_class.perform_now }

  let(:raw_data) { { "trn" => "1234567", "national_insurance_number" => "AB123456C", "date_of_birth" => "1980-01-01" } }
  let(:scrubbed_raw_data) { { "trn" => "1234567", "national_insurance_number" => "[REDACTED]", "date_of_birth" => "[REDACTED]" } }

  def create_version(object:, object_changes:, item_type: "Application")
    PaperTrail::Version.create!(item_type:, item_id: 1, event: "update", object:, object_changes:)
  end

  describe "#perform" do
    let!(:version) do
      create_version(
        object: { "id" => 1, "raw_application_data" => raw_data },
        object_changes: { "raw_application_data" => [raw_data, raw_data.merge("trn" => "7654321")] },
      )
    end

    it "scrubs the raw_application_data in object" do
      perform_job

      expect(version.reload.object).to eq("id" => 1, "raw_application_data" => scrubbed_raw_data)
    end

    it "scrubs the raw_application_data in object_changes" do
      perform_job

      expect(version.reload.object_changes).to eq(
        "raw_application_data" => [scrubbed_raw_data, scrubbed_raw_data.merge("trn" => "7654321")],
      )
    end

    it "reschedules itself to run again in 30 minutes time" do
      freeze_time

      expect { perform_job }.to have_enqueued_job(described_class).at(30.minutes.from_now)
    end

    context "when the version was created (object is null and the data was null before)" do
      let!(:version) do
        create_version(object: nil, object_changes: { "raw_application_data" => [nil, raw_data] })
      end

      it "scrubs the new data and keeps the nulls" do
        perform_job

        expect(version.reload.object).to be_nil
        expect(version.object_changes).to eq("raw_application_data" => [nil, scrubbed_raw_data])
      end
    end

    context "when the version does not have personal data" do
      let!(:version) do
        create_version(
          object: { "id" => 1, "raw_application_data" => { "trn" => "1234567" } },
          object_changes: { "lead_provider_approval_status" => %w[pending accepted] },
        )
      end

      it "does not change the version" do
        expect { perform_job }.not_to(change { version.reload.attributes })
      end

      it "does not reschedule itself" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the version is already scrubbed" do
      before { described_class.perform_now }

      it "does not reschedule itself" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the version is not for an Application" do
      let!(:version) do
        create_version(item_type: "User", object: { "raw_application_data" => raw_data }, object_changes: nil)
      end

      it "does not change the version" do
        expect { perform_job }.not_to(change { version.reload.object })
      end
    end

    context "when there are more versions than the batch size" do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
        create_version(object: { "raw_application_data" => { "date_of_birth" => "1990-01-01" } }, object_changes: nil)
      end

      it "only scrubs the oldest batch" do
        perform_job

        expect(PaperTrail::Version.order(:id).map { it.object.dig("raw_application_data", "date_of_birth") })
          .to eq(["[REDACTED]", "1990-01-01"])
      end
    end
  end
end
