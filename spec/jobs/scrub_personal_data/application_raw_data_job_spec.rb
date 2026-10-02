require "rails_helper"

RSpec.describe ScrubPersonalData::ApplicationRawDataJob, type: :job do
  subject(:perform_job) { described_class.perform_now }

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

    it "reschedules itself" do
      freeze_time

      expect { perform_job }.to have_enqueued_job(described_class).at(30.minutes.from_now)
    end

    context "when the personal data is missing or null" do
      let!(:application) do
        create(:application, raw_application_data: { "trn" => "1234567", "national_insurance_number" => nil })
      end

      it "does not change the data" do
        expect { perform_job }.not_to(change { application.reload.raw_application_data })
      end

      it "does not reschedule itself" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the data is already scrubbed" do
      before { described_class.perform_now }

      it "does not reschedule itself" do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context "when there are more applications than the batch size" do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
        create(:application, raw_application_data: { "date_of_birth" => "1990-01-01" })
      end

      it "only scrubs the oldest batch" do
        perform_job

        expect(Application.order(:id).map { it.raw_application_data["date_of_birth"] })
          .to eq([redacted, "1990-01-01"])
      end
    end
  end
end
