require "rails_helper"

RSpec.describe Forms::QualifiedTeacherCheck, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:trn) }
    it { is_expected.to validate_length_of(:trn).is_at_least(7).is_at_most(10) }
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_length_of(:full_name).is_at_most(128) }
    it { is_expected.to validate_presence_of(:date_of_birth) }
    it { is_expected.to validate_length_of(:national_insurance_number).is_at_most(9) }

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
        trn: "1234567",
        full_name: "John Doe",
        date_of_birth: Date.parse("1960-12-13"),
        national_insurance_number: "AB123456C",
      )
    end

    before do
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
        )
        .to_return(status: 200, body: dqt_response_body, headers: {})
    end

    context "when DQT match found" do
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
        subject.full_name = "Bob"
        subject.national_insurance_number = ""
      end

      it "returns :dqt_mismatch" do
        expect(subject.next_step).to eql(:dqt_mismatch)
      end

      it "marks trn_verified as falsey" do
        subject.next_step
        expect(subject.trn_verified?).to be_falsey
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
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 200, body: dqt_response_body, headers: {})

        subject.next_step
      end

      it "persists to store" do
        subject.after_save
        expect(wizard.store["active_alert"]).to eql(false)
      end
    end

    context "has active alerts" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 200, body: dqt_response_body(active_alert: true), headers: {})

        subject.next_step
      end

      it "persists to store" do
        subject.after_save
        expect(wizard.store["active_alert"]).to eql(true)
      end
    end

    context "trn has been verified" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567")
          .with(
            headers: {
              "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            },
          )
          .to_return(status: 200, body: dqt_response_body, headers: {})

        subject.next_step
      end

      it "persists to store" do
        subject.after_save
        expect(wizard.store["trn_verified"]).to eql(true)
      end
    end

    context "trn has not been verified" do
      before do
        stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567")
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
      end
    end
  end
end
