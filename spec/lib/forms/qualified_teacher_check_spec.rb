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
    end

    context "when DQT mismatch" do
      before do
        subject.full_name = "Bob"
        subject.national_insurance_number = ""
      end

      it "returns :dqt_mismatch" do
        expect(subject.next_step).to eql(:dqt_mismatch)
      end
    end
  end
end
