require "rails_helper"

RSpec.describe DqtRecord do
  let(:mock_client) { instance_double("Services::DqtClient") }
  let(:response) do
    {
      "teacher_reference_number" => "1234567",
      "full_name" => "John Doe",
      "date_of_birth" => "1960-01-13",
      "national_insurance_number" => "AB123456C",
      "qts_date" => "2010-12-14",
      "active_alert" => false,
    }
  end

  before do
    allow(mock_client).to receive(:call).and_return(response)
    allow(Services::DqtClient).to receive(:new).and_return(mock_client)
  end

  describe "::find" do
    context "when there is a record" do
      it "returns a DqtRecord instance" do
        expect(described_class.find(trn: "1234567")).to be_a(DqtRecord)
      end

      it "returns correct attributes" do
        instance = described_class.find(trn: "1234567")

        expect(instance.teacher_reference_number).to eql(response["teacher_reference_number"])
        expect(instance.full_name).to eql(response["full_name"])
        expect(instance.date_of_birth).to eql(Date.parse(response["date_of_birth"]))
        expect(instance.national_insurance_number).to eql(response["national_insurance_number"])
        expect(instance.qts_date).to eql(Date.parse(response["qts_date"]))
        expect(instance.active_alert).to eql(response["active_alert"])
      end
    end

    context "when there is no record" do
      let(:response) { nil }

      it "returns nil" do
        expect(described_class.find(trn: "123456")).to be_nil
      end
    end
  end

  describe "#fuzzy_match?" do
    subject do
      described_class.new(
        teacher_reference_number: "1234567",
        full_name: "John Doe",
        national_insurance_number: "AB123456c",
        active_alert: false,
        qts_date: "2000-12-13",
        date_of_birth: "1960-11-14",
      )
    end

    context "when all fields match" do
      it "returns true" do
        expect(
          subject.fuzzy_match?(
            full_name: "John Doe",
            date_of_birth: Date.parse("1960-11-14"),
            national_insurance_number: "AB123456C",
          ),
        ).to be_truthy
      end
    end

    context "when 2 fields match" do
      it "returns true" do
        expect(
          subject.fuzzy_match?(
            full_name: "John Doee",
            date_of_birth: Date.parse("1960-11-14"),
            national_insurance_number: "AB123456C",
          ),
        ).to be_truthy
      end
    end

    context "when 1 field matches" do
      it "returns false" do
        expect(
          subject.fuzzy_match?(
            full_name: "John Doee",
            date_of_birth: Date.parse("1960-11-15"),
            national_insurance_number: "AB123456C",
          ),
        ).to be_falsey
      end
    end

    context "when NI number is NULL" do
      subject do
        described_class.new(
          teacher_reference_number: "1234567",
          full_name: "John Doe",
          national_insurance_number: "NULL",
          active_alert: false,
          qts_date: "2000-12-13",
          date_of_birth: "1960-11-14",
        )
      end

      it "does not match against it" do
        expect(
          subject.fuzzy_match?(
            full_name: "John Doee",
            date_of_birth: Date.parse("1960-11-14"),
            national_insurance_number: "NULL",
          ),
        ).to be_falsey
      end
    end
  end
end
