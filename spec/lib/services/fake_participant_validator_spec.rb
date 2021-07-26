require "rails_helper"

RSpec.describe Services::FakeParticipantValidator do
  let(:trn) { rand(1_000_000..9_999_999).to_s }
  let(:date_of_birth) { rand(60.years.ago..20.years.ago).to_date }
  let(:national_insurance_number) { "AB123456C" }

  subject do
    described_class.new(
      trn: trn,
      full_name: full_name,
      date_of_birth: date_of_birth,
      national_insurance_number: national_insurance_number,
    )
  end

  describe "#call" do
    context "when user called John" do
      let(:full_name) { "John Doe" }

      it "returns record with matching trn" do
        expect(subject.call.trn).to eql(trn)
        expect(subject.call.active_alert).to be_falsey
      end
    end

    context "when user called Jane" do
      let(:full_name) { "Jane Doe" }

      it "returns record with matching trn" do
        expect(subject.call.trn).to eql(trn)
        expect(subject.call.active_alert).to be_falsey
      end
    end

    context "when user not called John or Jane" do
      let(:full_name) { "Jack Doe" }

      it "returns nil" do
        expect(subject.call).to be_nil
      end
    end
  end
end
