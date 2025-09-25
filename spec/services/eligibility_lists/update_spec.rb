# frozen_string_literal: true

require "rails_helper"

RSpec.describe EligibilityLists::Update, type: :model do
  subject(:service) { described_class.new(eligibility_list_type:, file:) }

  let(:eligibility_list_type) { "EligibilityList::Pp50School" }
  let(:file) { tempfile_with_bom("#{EligibilityList::Pp50School::IDENTIFIER_HEADER},other\n#{urn},whatever\n") }
  let(:urn) { "100001" }

  before do
    create(:eligibility_list_entry, :pp50_school, identifier: "200000")
    create(:eligibility_list_entry, :pp50_school, identifier: "300000")
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:file).with_message("Please choose a file") }

    context "when the file has invalid headers" do
      let(:file) { tempfile_with_bom("Invalid Header\n#{urn}\n") }

      it "is not valid" do
        expect(subject).to have_error(:file, :invalid_headers)
      end
    end

    context "when the file has no data rows" do
      let(:file) { tempfile_with_bom("#{EligibilityList::Pp50School::IDENTIFIER_HEADER}\n") }

      it "is not valid" do
        expect(subject).to have_error(:file, :empty)
      end
    end
  end

  describe "#call" do
    subject { service.call }

    it "deletes existing records for that eligibility list type" do
      expect { subject }.to change(EligibilityList::Pp50School, :count).from(2).to(1)
    end

    it "creates new records from the uploaded file" do
      expect { subject }.to change {
        EligibilityList::Pp50School.where(identifier: urn, identifier_type: EligibilityList::Pp50School::IDENTIFIER_TYPE).count
      }.from(0).to(1)
    end
  end
end
