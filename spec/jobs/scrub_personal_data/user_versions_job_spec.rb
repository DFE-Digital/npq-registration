require "rails_helper"

RSpec.describe ScrubPersonalData::UserVersionsJob, type: :job do
  subject(:perform_job) { described_class.perform_now }

  def create_version(object:, object_changes:, item_type: "User")
    PaperTrail::Version.create!(item_type:, item_id: 1, event: "update", object:, object_changes:)
  end

  describe "#perform" do
    let!(:version) do
      create_version(
        object: {
          "full_name" => "John Doe",
          "national_insurance_number" => "AB123456C",
          "date_of_birth" => "1980-01-01",
          "raw_tra_provider_data" => { "info" => { "birthdate" => "1980-01-01" } },
        },
        object_changes: {
          "full_name" => ["John", "John Doe"],
          "national_insurance_number" => [nil, "AB123456C"],
        },
      )
    end

    it "scrubs the personal data in object" do
      perform_job

      expect(version.reload.object).to eq(
        "full_name" => "John Doe",
        "national_insurance_number" => "[REDACTED]",
        "date_of_birth" => "[REDACTED]",
        "raw_tra_provider_data" => "[REDACTED]",
      )
    end

    it "scrubs the personal data in object_changes" do
      perform_job

      expect(version.reload.object_changes).to eq(
        "full_name" => ["John", "John Doe"],
        "national_insurance_number" => ["[REDACTED]", "[REDACTED]"],
      )
    end

    it "reschedules itself" do
      freeze_time

      expect { perform_job }.to have_enqueued_job(described_class).at(30.minutes.from_now)
    end

    context "when the personal data is missing or null" do
      let!(:version) do
        create_version(
          object: { "full_name" => "John Doe", "date_of_birth" => nil },
          object_changes: { "full_name" => ["John", "John Doe"] },
        )
      end

      it "does not change the version" do
        expect { perform_job }.not_to(change { version.reload.attributes })
      end

      it "does not reschedule itself" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the version was created, so object is null" do
      let!(:version) do
        create_version(
          object: nil,
          object_changes: { "date_of_birth" => [nil, "1980-01-01"] },
        )
      end

      it "scrubs object_changes and keeps object null" do
        perform_job

        expect(version.reload.object).to be_nil
        expect(version.object_changes).to eq("date_of_birth" => ["[REDACTED]", "[REDACTED]"])
      end
    end

    context "when the version is already scrubbed" do
      before { described_class.perform_now }

      it "does not reschedule itself" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the version is not for a User" do
      let!(:version) do
        create_version(
          item_type: "Application",
          object: { "date_of_birth" => "1980-01-01" },
          object_changes: nil,
        )
      end

      it "does not change the version" do
        expect { perform_job }.not_to(change { version.reload.object })
      end
    end

    context "when there are more versions than the batch size" do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
        create_version(object: { "date_of_birth" => "1990-01-01" }, object_changes: nil)
      end

      it "only scrubs one batch, oldest first" do
        perform_job

        expect(PaperTrail::Version.order(:id).map { it.object["date_of_birth"] })
          .to eq(["[REDACTED]", "1990-01-01"])
      end
    end
  end
end
