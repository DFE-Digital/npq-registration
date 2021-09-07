require "rails_helper"

RSpec.describe Forms::QualifiedTeacherCheck, type: :model do
  describe "before validations" do
    subject do
      described_class.new(
        trn: "  1234  567  ",
        full_name: "  John     O’Doe   ",
        national_insurance_number: "  AB 12 34 56 C ",
      )
    end

    it "strips superflous whitespace from TRN" do
      subject.valid?
      expect(subject.trn).to eql("1234567")
    end

    it "strips superflous whitespace from full_name + converts smart quotes" do
      subject.valid?
      expect(subject.full_name).to eql("John O'Doe")
    end

    it "strips superflous whitespace from NI number" do
      subject.valid?
      expect(subject.national_insurance_number).to eql("AB123456C")
    end

    context "full_name with titles" do
      it "removes leading titles from full_name" do
        subject.full_name = "Mr John Doe"
        subject.valid?
        expect(subject.full_name).to eql("John Doe")

        subject.full_name = "MR JOHN DOE"
        subject.valid?
        expect(subject.full_name).to eql("JOHN DOE")

        subject.full_name = "Mr. John Doe"
        subject.valid?
        expect(subject.full_name).to eql("John Doe")

        subject.full_name = "Ms Jane Doe"
        subject.valid?
        expect(subject.full_name).to eql("Jane Doe")

        subject.full_name = "Ms. Jane Doe"
        subject.valid?
        expect(subject.full_name).to eql("Jane Doe")

        subject.full_name = "Mrs Jane Doe"
        subject.valid?
        expect(subject.full_name).to eql("Jane Doe")

        subject.full_name = "Mrs. Jane Doe"
        subject.valid?
        expect(subject.full_name).to eql("Jane Doe")

        subject.full_name = "Miss Jane Doe"
        subject.valid?
        expect(subject.full_name).to eql("Jane Doe")

        subject.full_name = "Miss. Jane Doe"
        subject.valid?
        expect(subject.full_name).to eql("Jane Doe")
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:trn) }
    it { is_expected.to validate_length_of(:trn).is_at_least(5).is_at_most(7) }
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_length_of(:full_name).is_at_most(128) }
    it { is_expected.to validate_presence_of(:date_of_birth) }
    it { is_expected.to validate_length_of(:national_insurance_number).is_at_most(9) }

    describe "#trn" do
      it "can only contain numbers" do
        subject.trn = "123456a"
        subject.valid?
        expect(subject.errors[:trn]).to be_present
      end
    end

    describe "#date_of_birth" do
      it "must be in the past" do
        subject.date_of_birth = 1.week.from_now
        subject.valid?
        expect(subject.errors[:date_of_birth]).to be_present

        subject.date_of_birth = 20.years.ago
        subject.valid?
        expect(subject.errors[:date_of_birth]).to be_blank
      end

      it "must be a valid date" do
        subject.date_of_birth = { 3 => 1, 2 => 13, 1 => 1990 }
        subject.valid?
        expect(subject.errors.of_kind?(:date_of_birth, :invalid)).to be_truthy

        subject.date_of_birth = { 3 => 1, 2 => 12, 1 => 1990 }
        subject.valid?
        expect(subject.errors.of_kind?(:date_of_birth, :invalid)).to be_falsey
      end
    end
  end

  describe "#next_step" do
    subject do
      described_class.new(
        trn: "RP12/34567",
        full_name: "John Doe",
        date_of_birth: Date.parse("1960-12-13"),
        national_insurance_number: "AB123456C",
      )
    end

    context "when DQT match found" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/participant-validation/1234567?date_of_birth=1960-12-13&full_name=John%20Doe&nino=AB123456C")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 200, body: participant_validator_response, headers: {})
      end

      it "returns :choose_your_npq" do
        expect(subject.next_step).to eql(:choose_your_npq)
      end

      it "marks trn_verified as truthy" do
        subject.next_step
        expect(subject.trn_verified?).to be_truthy
      end
    end

    context "when DQT mismatch" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/participant-validation/1234567?date_of_birth=1960-12-13&full_name=John%20Doe&nino=AB123456C")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 404, body: "", headers: {})
      end

      it "returns :dqt_mismatch" do
        expect(subject.next_step).to eql(:dqt_mismatch)
      end

      it "marks trn_verified as falsey" do
        subject.next_step
        expect(subject.trn_verified?).to be_falsey
      end
    end

    context "exception is raised" do
      before do
        mock_validator = instance_double(Services::ParticipantValidator)
        allow(Services::ParticipantValidator).to receive(:new).and_return(mock_validator)
        allow(mock_validator).to receive(:call).and_raise(StandardError)
      end

      it "returns :dqt_mismatch" do
        expect(subject.next_step).to eql(:dqt_mismatch)
      end

      it "marks trn_verified as falsey" do
        subject.next_step
        expect(subject.trn_verified?).to be_falsey
      end

      it "notifies sentry" do
        allow(Sentry).to receive(:capture_exception)
        subject.next_step
        expect(Sentry).to have_received(:capture_exception)
      end
    end
  end

  describe "#after_save" do
    let(:store) { {} }
    let(:request) { nil }

    let(:wizard) do
      RegistrationWizard.new(
        current_step: :qualified_teacher_check,
        store: store,
        request: request,
      )
    end

    subject do
      described_class.new(
        trn: "1234567",
        full_name: "John Doe",
        date_of_birth: Date.parse("1960-12-13"),
        national_insurance_number: "AB123456C",
        wizard: wizard,
      )
    end

    context "has no active alerts" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/participant-validation/1234567?date_of_birth=1960-12-13&full_name=John%20Doe&nino=AB123456C")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 200, body: participant_validator_response, headers: {})

        subject.next_step
      end

      it "persists to store" do
        subject.after_save
        expect(wizard.store["active_alert"]).to eql(false)
      end
    end

    context "has active alerts" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/participant-validation/1234567?date_of_birth=1960-12-13&full_name=John%20Doe&nino=AB123456C")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 200, body: participant_validator_response(active_alert: true), headers: {})

        subject.next_step
      end

      it "persists to store" do
        subject.after_save
        expect(wizard.store["active_alert"]).to eql(true)
      end
    end

    context "trn has been verified" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/participant-validation/1234567?date_of_birth=1960-12-13&full_name=John%20Doe&nino=AB123456C")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 200, body: participant_validator_response, headers: {})

        subject.next_step
      end

      it "persists to store" do
        subject.after_save
        expect(wizard.store["trn_verified"]).to eql(true)
        expect(wizard.store["trn_auto_verified"]).to eql(true)
        expect(wizard.store["verified_trn"]).to eql("1234567")
      end
    end

    context "when different trn found" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/participant-validation/1234567?date_of_birth=1960-12-13&full_name=John%20Doe&nino=AB123456C")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 200, body: participant_validator_response(trn: "1111111"), headers: {})

        subject.next_step
      end

      it "persists to store" do
        subject.after_save
        expect(wizard.store["trn_verified"]).to eql(true)
        expect(wizard.store["trn_auto_verified"]).to eql(true)
        expect(wizard.store["verified_trn"]).to eql("1111111")
      end
    end

    context "trn has not been verified" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/participant-validation/1234567?date_of_birth=1960-12-13&full_name=John%20Doe&nino=AB123456C")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 404, body: "", headers: {})

        subject.next_step
      end

      it "persists to store" do
        subject.after_save
        expect(wizard.store["trn_verified"]).to eql(false)
        expect(wizard.store["trn_auto_verified"]).to be_falsey
      end
    end
  end
end
