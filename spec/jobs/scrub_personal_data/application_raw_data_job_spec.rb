require "rails_helper"

RSpec.describe ScrubPersonalData::ApplicationRawDataJob, type: :job do
  subject(:perform_job) { described_class.perform_now(**perform_args) }

  let(:perform_args) { { reschedule: true } }
  let(:redacted) { "[REDACTED]" }

  describe "#perform" do
    let!(:application) do
      create(:application, raw_application_data: {
        "trn" => "1234567",
        "national_insurance_number" => "AB123456C",
        "date_of_birth" => "1980-01-01",
      })
    end

    it "scrubs the personal data" do
      perform_job

      expect(application.reload.raw_application_data).to eq(
        "trn" => "1234567",
        "national_insurance_number" => redacted,
        "date_of_birth" => redacted,
      )
    end

    it "does not touch updated_at" do
      expect { perform_job }.not_to(change { application.reload.updated_at })
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

        expect(application.reload.raw_application_data["date_of_birth"]).to eq(redacted)
      end
    end

    context "when the personal data is blank" do
      let!(:application) do
        create(:application, raw_application_data: {
          "trn" => "1234567",
          "national_insurance_number" => "",
          "date_of_birth" => "",
        })
      end

      it "leaves the blank values alone, there is nothing to scrub" do
        expect { perform_job }.not_to(change { application.reload.raw_application_data })
      end

      it "does not reschedule itself again" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when only one of the fields is blank" do
      let!(:application) do
        create(:application, raw_application_data: {
          "national_insurance_number" => "",
          "date_of_birth" => "1980-01-01",
        })
      end

      it "scrubs the other one and keeps the blank" do
        perform_job

        expect(application.reload.raw_application_data).to eq(
          "national_insurance_number" => "",
          "date_of_birth" => redacted,
        )
      end
    end

    context "when one of the keys is not in the data" do
      let!(:application) do
        create(:application, raw_application_data: { "trn" => "1234567", "date_of_birth" => "1980-01-01" })
      end

      it "scrubs the other one, it keeps the rest of the data and it does not add the missing key" do
        perform_job

        expect(application.reload.raw_application_data).to eq(
          "trn" => "1234567",
          "date_of_birth" => redacted,
        )
      end
    end

    context "when the personal data is missing or null" do
      let!(:application) do
        create(:application, raw_application_data: { "trn" => "1234567", "national_insurance_number" => nil })
      end

      it "does not change the data" do
        expect { perform_job }.not_to(change { application.reload.raw_application_data })
      end

      it "does not reschedule itself again" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the data is already scrubbed" do
      before { described_class.perform_now }

      it "does not reschedule itself again" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when there are more applications than the batch size" do
      let(:perform_args) { { batch_size: 1, reschedule: true } }

      before { create(:application, raw_application_data: { "date_of_birth" => "1990-01-01" }) }

      it "only scrubs one batch, oldest first" do
        perform_job

        expect(Application.order(:id).map { it.raw_application_data["date_of_birth"] })
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
