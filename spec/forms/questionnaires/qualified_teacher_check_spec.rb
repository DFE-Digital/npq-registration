require "rails_helper"

RSpec.describe Questionnaires::QualifiedTeacherCheck, type: :model do
  def stub_api_request(trn:, date_of_birth:, nino:, response_code: 200, response_body: "")
    stub_request(:get, "https://dqt-api.example.com/v1/teachers/#{trn}?birthdate=#{date_of_birth}&nino=#{nino}")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer test-apikey",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: response_code, body: response_body, headers: {})
  end

  let(:current_user) do
    create(:user,
           email: "mail@example.com",
           date_of_birth: Date.new(1980, 10, 20),
           trn: nil,
           trn_lookup_status: "Failed",
           trn_verified: false,
           full_name: "Jane Doe",
           raw_tra_provider_data: {},
           updated_from_tra_at: Time.zone.now)
  end
  let(:wizard) { RegistrationWizard.new(store:, request:, current_step: :qualified_teacher_check, current_user:) }
  let(:request) { nil }
  let(:store) do
    { "teacher_catchment" => "england" }
  end

  before do
    subject.wizard = wizard
  end

  describe "before validations" do
    subject do
      described_class.new(
        trn: "  1234  567  ",
        full_name: "  Jane     O’Doe   ",
        national_insurance_number: "  AB 12 34 56 C ",
      )
    end

    it "strips superflous whitespace from TRN" do
      subject.valid?
      expect(subject.trn).to eql("1234567")
    end

    it "strips superflous whitespace from full_name + converts smart quotes" do
      subject.valid?
      expect(subject.full_name).to eql("Jane O'Doe")
    end

    it "strips superflous whitespace from NI number" do
      subject.valid?
      expect(subject.national_insurance_number).to eql("AB123456C")
    end

    context "full_name with titles" do
      it "removes leading titles from full_name" do
        subject.full_name = "Ms Jane Doe"
        subject.valid?
        expect(subject.full_name).to eql("Jane Doe")

        subject.full_name = "MS JANE DOE"
        subject.valid?
        expect(subject.full_name).to eql("JANE DOE")

        subject.full_name = "Ms. Jane Doe"
        subject.valid?
        expect(subject.full_name).to eql("Jane Doe")

        subject.full_name = "Mr John Doe"
        subject.valid?
        expect(subject.full_name).to eql("John Doe")

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
    it { is_expected.to validate_presence_of(:trn).with_message("Teacher reference number cannot be blank") }
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_length_of(:full_name).is_at_most(128) }
    it { is_expected.to validate_presence_of(:date_of_birth) }
    it { is_expected.to validate_length_of(:national_insurance_number).is_at_most(9) }

    describe "TRN validations" do
      it "can only contain numbers" do
        subject.trn = "123456a"
        subject.valid?
        expect(subject.errors[:trn]).to eq ["Teacher reference number must only contain numbers"]
      end

      it "doesn't permit nil TRN" do
        subject.trn = nil
        subject.valid?
        expect(subject.errors[:trn]).to eq ["Teacher reference number cannot be blank"]
      end

      it "doesn't permit empty TRN" do
        subject.trn = ""
        subject.valid?
        expect(subject.errors[:trn]).to eq ["Teacher reference number cannot be blank"]
      end

      it "doesn't permit legacy style TRNs" do
        subject.trn = "RP99/12345"
        subject.valid?
        expect(subject.errors[:trn]).to eq ["Teacher reference number must only contain numbers"]
      end

      it "denies trns over 7 characters" do
        subject.trn = "99123456"
        subject.valid?
        expect(subject.errors[:trn]).to eq ["Teacher reference number is 7 digits long"]
      end

      it "denies trns under 7 characters" do
        subject.trn = "1234"
        subject.valid?
        expect(subject.errors[:trn]).to eq ["Teacher reference number is 7 digits long"]
      end

      it "denies trns with other letters" do
        subject.trn = "AA99/12345"
        subject.valid?
        expect(subject.errors[:trn]).to eq ["Teacher reference number must only contain numbers"]
      end

      it "denies fake trn 0000000" do
        subject.trn = "0000000"
        subject.valid?
        expect(subject.errors[:trn]).to eq ["You must enter a valid teacher reference number (TRN)"]
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
        expect(subject.errors).to be_of_kind(:date_of_birth, :invalid)

        subject.date_of_birth = { 3 => 1, 2 => 12, 1 => 1990 }
        subject.valid?
        expect(subject.errors).not_to be_of_kind(:date_of_birth, :invalid)
      end
    end
  end

  describe "#requirements_met?" do
    it { is_expected.to be_requirements_met }

    context "without current user" do
      let(:current_user) { nil }

      it { is_expected.not_to be_requirements_met }
    end
  end

  describe "#next_step" do
    subject do
      described_class.new(
        trn: "RP12/34567",
        full_name: "Jane Doe",
        date_of_birth: Date.parse("1960-12-13"),
        national_insurance_number: "AB123456C",
      )
    end

    let(:wizard) { RegistrationWizard.new(store:, request:, current_step: :qualified_teacher_check, current_user:) }
    let(:request) { nil }
    let(:store) do
      { "teacher_catchment" => "england" }
    end

    before do
      subject.wizard = wizard
    end

    context "when DQT match found" do
      before do
        stub_api_request(
          trn: "1234567",
          date_of_birth: "1960-12-13",
          nino: "AB123456C",
          response_body: dqt_response_body,
        )
      end

      it "marks trn_verified as truthy" do
        subject.next_step
        expect(subject).to be_trn_verified
      end

      it "returns :course_start_date" do
        expect(subject.next_step).to be(:course_start_date)
      end
    end

    context "when DQT mismatch" do
      before do
        stub_api_request(
          trn: "1234567",
          date_of_birth: "1960-12-13",
          nino: "AB123456C",
          response_code: 404,
        )
      end

      it "returns :dqt_mismatch" do
        expect(subject.next_step).to be(:dqt_mismatch)
      end

      it "marks trn_verified as falsey" do
        subject.next_step
        expect(subject).not_to be_trn_verified
      end
    end

    context "exception is raised" do
      before do
        mock_validator = instance_double(ParticipantValidator)
        allow(ParticipantValidator).to receive(:new).and_return(mock_validator)
        allow(mock_validator).to receive(:call).and_raise(StandardError)
      end

      it "returns :dqt_mismatch" do
        expect(subject.next_step).to be(:dqt_mismatch)
      end

      it "marks trn_verified as falsey" do
        subject.next_step
        expect(subject).not_to be_trn_verified
      end

      it "notifies sentry" do
        allow(Sentry).to receive(:capture_exception)
        subject.next_step
        expect(Sentry).to have_received(:capture_exception)
      end
    end
  end

  describe "#after_save" do
    subject do
      described_class.new(
        trn: trn,
        full_name: "Jane Smith",
        date_of_birth: Date.parse("1960-12-13"),
        national_insurance_number: "AB123456C",
        wizard:,
      )
    end

    let(:store) { {} }
    let(:request) { nil }
    let(:trn) { "1234567" }
    let(:dqt_check_trn) { trn }

    let(:wizard) do
      RegistrationWizard.new(
        current_step: :qualified_teacher_check,
        store:,
        request:,
        current_user:,
      )
    end

    context "trn has been verified" do
      before do
        stub_api_request(
          trn: dqt_check_trn,
          date_of_birth: "1960-12-13",
          nino: "AB123456C",
          response_body: dqt_response_body(trn:),
        )

        subject.next_step
      end

      it "persists to store" do
        expect {
          subject.after_save
        }.to change {
          current_user.reload.slice(
            :active_alert,
            :date_of_birth,
            :full_name,
            :national_insurance_number,
            :trn,
            :trn_auto_verified,
            :trn_lookup_status,
            :trn_verified,
          )
        }.from(
          {
            "active_alert" => false,
            "date_of_birth" => Date.new(1980, 10, 20),
            "full_name" => "Jane Doe",
            "national_insurance_number" => nil,
            "trn" => nil,
            "trn_auto_verified" => false,
            "trn_lookup_status" => "Failed",
            "trn_verified" => false,
          },
        ).to(
          {
            "active_alert" => false,
            "date_of_birth" => Date.new(1960, 12, 13),
            "full_name" => "Jane Smith",
            "national_insurance_number" => nil,
            "trn" => "1234567",
            "trn_auto_verified" => true,
            "trn_lookup_status" => "Found",
            "trn_verified" => true,
          },
        )
      end

      context "TRN is less than 7 characters long" do
        let(:trn) { "12345" }
        let(:dqt_check_trn) { "0012345" }

        it "pads the TRN when persisting to store" do
          expect {
            subject.after_save
          }.to change {
            current_user.reload.slice(
              :trn,
              :trn_auto_verified,
              :trn_lookup_status,
              :trn_verified,
            )
          }.from(
            {
              "trn" => nil,
              "trn_auto_verified" => false,
              "trn_lookup_status" => "Failed",
              "trn_verified" => false,
            },
          ).to(
            {
              "trn" => "0012345",
              "trn_auto_verified" => true,
              "trn_lookup_status" => "Found",
              "trn_verified" => true,
            },
          )
        end
      end
    end

    context "has active alerts" do
      before do
        stub_api_request(
          trn: "1234567",
          date_of_birth: "1960-12-13",
          nino: "AB123456C",
          response_body: dqt_response_body(active_alert: true),
        )

        subject.next_step
      end

      it "persists to store" do
        expect {
          subject.after_save
        }.to change {
          current_user.reload.slice(
            :active_alert,
            :date_of_birth,
            :full_name,
            :national_insurance_number,
            :trn,
            :trn_auto_verified,
            :trn_lookup_status,
            :trn_verified,
          )
        }.from(
          {
            "active_alert" => false,
            "date_of_birth" => Date.new(1980, 10, 20),
            "full_name" => "Jane Doe",
            "national_insurance_number" => nil,
            "trn" => nil,
            "trn_auto_verified" => false,
            "trn_lookup_status" => "Failed",
            "trn_verified" => false,
          },
        ).to(
          {
            "active_alert" => true,
            "date_of_birth" => Date.new(1960, 12, 13),
            "full_name" => "Jane Smith",
            "national_insurance_number" => nil,
            "trn" => "1234567",
            "trn_auto_verified" => true,
            "trn_lookup_status" => "Found",
            "trn_verified" => true,
          },
        )
      end
    end

    context "when different trn found" do
      before do
        stub_api_request(
          trn: "1234567",
          date_of_birth: "1960-12-13",
          nino: "AB123456C",
          response_body: dqt_response_body(trn: "1111111"),
        )

        subject.next_step
      end

      it "persists to store" do
        expect {
          subject.after_save
        }.to change {
          current_user.reload.slice(
            :active_alert,
            :date_of_birth,
            :full_name,
            :national_insurance_number,
            :national_insurance_number,
            :trn,
            :trn_auto_verified,
            :trn_lookup_status,
            :trn_verified,
          )
        }.from(
          {
            "active_alert" => false,
            "date_of_birth" => Date.new(1980, 10, 20),
            "full_name" => "Jane Doe",
            "national_insurance_number" => nil,
            "trn" => nil,
            "trn_auto_verified" => false,
            "trn_lookup_status" => "Failed",
            "trn_verified" => false,
          },
        ).to(
          {
            "active_alert" => false,
            "date_of_birth" => Date.new(1960, 12, 13),
            "full_name" => "Jane Smith",
            "national_insurance_number" => nil,
            "trn" => "1111111",
            "trn_auto_verified" => true,
            "trn_lookup_status" => "Found",
            "trn_verified" => true,
          },
        )
      end
    end

    context "trn has not been verified" do
      before do
        stub_api_request(
          trn: dqt_check_trn,
          date_of_birth: "1960-12-13",
          nino: "AB123456C",
          response_code: 404,
        )

        subject.next_step
      end

      it "persists to store" do
        expect {
          subject.after_save
        }.to change {
          current_user.reload.slice(
            :active_alert,
            :date_of_birth,
            :full_name,
            :national_insurance_number,
            :trn,
            :trn_auto_verified,
            :trn_lookup_status,
            :trn_verified,
          )
        }.from(
          {
            "active_alert" => false,
            "date_of_birth" => Date.new(1980, 10, 20),
            "full_name" => "Jane Doe",
            "national_insurance_number" => nil,
            "trn" => nil,
            "trn_auto_verified" => false,
            "trn_lookup_status" => "Failed",
            "trn_verified" => false,
          },
        ).to(
          {
            "active_alert" => nil,
            "date_of_birth" => Date.new(1960, 12, 13),
            "full_name" => "Jane Smith",
            "national_insurance_number" => "AB123456C",
            "trn" => "1234567",
            "trn_auto_verified" => false,
            "trn_lookup_status" => "Failed",
            "trn_verified" => false,
          },
        )
      end

      context "TRN is less than 7 characters long" do
        let(:trn) { "12345" }
        let(:dqt_check_trn) { "0012345" }

        it "pads the TRN when persisting to store" do
          expect {
            subject.after_save
          }.to change {
            current_user.reload.slice(
              :trn,
              :trn_auto_verified,
              :trn_lookup_status,
              :trn_verified,
            )
          }.from(
            {
              "trn" => nil,
              "trn_auto_verified" => false,
              "trn_lookup_status" => "Failed",
              "trn_verified" => false,
            },
          ).to(
            {
              "trn" => "0012345",
              "trn_auto_verified" => false,
              "trn_lookup_status" => "Failed",
              "trn_verified" => false,
            },
          )
        end
      end
    end

    it_behaves_like "coping with an expired or non-existent session"
  end
end
