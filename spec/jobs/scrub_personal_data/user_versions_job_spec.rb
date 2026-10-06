require "rails_helper"

RSpec.describe ScrubPersonalData::UserVersionsJob, type: :job do
  subject(:perform_job) { described_class.perform_now(**perform_args) }

  let(:perform_args) { { reschedule: true } }
  let(:redacted) { "[REDACTED]" }

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
        "national_insurance_number" => redacted,
        "date_of_birth" => redacted,
        "raw_tra_provider_data" => redacted,
      )
    end

    it "scrubs the personal data in object_changes, keeping the nulls" do
      perform_job

      expect(version.reload.object_changes).to eq(
        "full_name" => ["John", "John Doe"],
        "national_insurance_number" => [nil, redacted],
      )
    end

    it "reschedules itself again" do
      freeze_time

      expect { perform_job }.to have_enqueued_job(described_class)
        .with(batch_size: described_class::BATCH_SIZE, reschedule: true)
        .at(30.minutes.from_now)
    end

    context "when it is run without reschedule" do
      let(:perform_args) { {} }

      it "scrubs the personal data but does not reschedule itself again" do
        expect { perform_job }.not_to have_enqueued_job(described_class)

        expect(version.reload.object["date_of_birth"]).to eq(redacted)
      end
    end

    context "when only some of the fields are present" do
      let!(:version) do
        create_version(
          object: { "full_name" => "John Doe", "date_of_birth" => "1980-01-01" },
          object_changes: { "date_of_birth" => [nil, "1980-01-01"] },
        )
      end

      it "scrubs them and does not add the missing ones" do
        perform_job

        expect(version.reload.object).to eq("full_name" => "John Doe", "date_of_birth" => redacted)
        expect(version.object_changes).to eq("date_of_birth" => [nil, redacted])
      end
    end

    context "when the personal data is blank" do
      let!(:version) do
        create_version(
          object: { "national_insurance_number" => "", "date_of_birth" => "" },
          object_changes: { "national_insurance_number" => ["", ""] },
        )
      end

      it "leaves the blank values alone, there is nothing to scrub" do
        expect { perform_job }.not_to(change { version.reload.attributes })
      end

      it "does not reschedule itself again" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
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

      it "does not reschedule itself again" do
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
        expect(version.object_changes).to eq("date_of_birth" => [nil, redacted])
      end
    end

    context "when the version is already scrubbed" do
      before { described_class.perform_now }

      it "does not reschedule itself again" do
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
      let(:perform_args) { { batch_size: 1, reschedule: true } }

      before { create_version(object: { "date_of_birth" => "1990-01-01" }, object_changes: nil) }

      it "only scrubs one batch" do
        perform_job

        expect(PaperTrail::Version.order(:id).map { it.object["date_of_birth"] })
          .to eq([redacted, "1990-01-01"])
      end

      it "reschedules itself again with the same batch size" do
        freeze_time

        expect { perform_job }.to have_enqueued_job(described_class)
          .with(batch_size: 1, reschedule: true)
          .at(30.minutes.from_now)
      end
    end
  end
end
