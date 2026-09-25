require "rails_helper"

RSpec.describe TeachingRecordHelper, type: :helper do
  describe "#trs_person_url" do
    context "with a trn" do
      subject { trs_person_url("123456") }

      it { is_expected.to eq "https://preprod.teaching-record-system.education.gov.uk/persons?Search=123456" }
    end

    context "without a trn" do
      subject { trs_person_url("  ") }

      it { is_expected.to be_nil }
    end
  end

  describe "#trs_search_url" do
    subject { trs_search_url }

    it { is_expected.to eq "https://preprod.teaching-record-system.education.gov.uk/persons" }
  end
end
