# frozen_string_literal: true

require "rails_helper"

RSpec.describe EligibilityLists::Update, type: :model do
  subject(:service) { described_class.new(eligibility_list_type:, file:) }

  let(:eligibility_list_type) { "EligibilityList::Pp50School" }
  let(:file) { tempfile_with_bom("#{EligibilityList::Pp50School::IDENTIFIER_CSV_HEADERS.first},other\n #{urn} ,whatever\n") }
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
        expect(subject).to have_error(:file, :invalid_headers, "Uploaded file has incorrect header")
      end
    end

    context "when the file has no data rows" do
      let(:file) { tempfile_with_bom("#{EligibilityList::Pp50School::IDENTIFIER_CSV_HEADERS.first}\n") }

      it "is not valid" do
        expect(subject).to have_error(:file, :empty, "Uploaded file is empty")
      end
    end

    context "when the file is empty" do
      let(:file) { tempfile_with_bom("") }

      it "is not valid" do
        expect(subject).to have_error(:file, :invalid_headers, "Uploaded file has incorrect header")
      end
    end

    context "when the file is not a CSV" do
      let(:file) { tempfile_with_bom('"URN,') }

      it "is not valid" do
        expect(subject).to have_error(:file, :invalid, "Uploaded file is not a valid CSV")
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

    context "when there are characters with ISO-8859-1 encoding" do
      let(:eligibility_list_type) { "EligibilityList::DisadvantagedEarlyYearsSchool" }
      let(:file) { File.open(Rails.root.join("spec/fixtures/files/disadvantaged_ey_eligibility_list_iso_8859_1_encoding.csv")) }
      let(:urn) { "107747" } # value from the fixture file

      it "creates new records correctly" do
        subject
        expect(service).to be_valid
        expect(EligibilityList::DisadvantagedEarlyYearsSchool.where(identifier: urn, identifier_type: :urn).count).to eq 1
      end
    end

    context "when there are rows in the CSV with the same identifier" do
      let(:eligibility_list_type) { "EligibilityList::DisadvantagedEarlyYearsSchool" }
      let(:file) { tempfile_with_bom("#{EligibilityList::DisadvantagedEarlyYearsSchool::IDENTIFIER_CSV_HEADERS.join(',')}\n#{urn} , \n900001 ,#{urn} ") }

      it "ignores duplicates" do
        subject
        expect(EligibilityList::DisadvantagedEarlyYearsSchool.where(identifier: urn, identifier_type: :urn).count).to eq 1
      end
    end

    context "when the eligibility list type has multiple identifier columns (DisadvantagedEarlyYearsSchool)" do
      let(:eligibility_list_type) { "EligibilityList::DisadvantagedEarlyYearsSchool" }
      let(:file) { tempfile_with_bom("#{EligibilityList::DisadvantagedEarlyYearsSchool::IDENTIFIER_CSV_HEADERS.join(',')},other\n#{urn} , ,whatever\n100001 ,#{ofsted_urn} ,whatever") }
      let(:urn) { "100001" }
      let(:ofsted_urn) { "200002" }

      it "creates new records using the ofsted URN if it is available" do
        subject
        expect(EligibilityList::DisadvantagedEarlyYearsSchool.where(identifier: ofsted_urn, identifier_type: :urn).count).to eq 1
        expect(EligibilityList::DisadvantagedEarlyYearsSchool.where(identifier: urn, identifier_type: :urn).count).to eq 1
      end
    end
  end
end
