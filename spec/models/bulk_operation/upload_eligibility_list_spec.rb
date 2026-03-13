require "rails_helper"

RSpec.describe BulkOperation::UploadEligibilityList, type: :model do
  let(:admin) { create(:admin) }

  let(:valid_file) do
    tempfile <<~CSV
      PP50 School URN
      100000
    CSV
  end

  describe "validations" do
    let(:empty_file) { Tempfile.new }

    let(:no_header_file) do
      tempfile <<~CSV
        100000
      CSV
    end

    let(:only_headers_file) do
      tempfile <<~CSV
        PP50 School URN
      CSV
    end

    let(:malformed_csv_file) do
      tempfile <<~CSV
        "URN,
      CSV
    end

    let(:invalid_header_file) do
      tempfile <<~CSV
        Invalid Header
        100000
      CSV
    end

    let(:valid_file_extra_columns) do
      tempfile <<~CSV
        PP50 School URN,Extra Column
        100000,Extra Data
      CSV
    end

    let(:valid_file_whitespace_in_headers) do
      tempfile <<~CSV
        PP50 School URN , Extra Column
        100000,Extra Data
      CSV
    end

    subject(:bulk_operation) { BulkOperation::UploadEligibilityList::Pp50School.new(admin:) }

    it { is_expected.to validate_presence_of(:file).with_message("Please choose a file") }

    it "allows a valid file" do
      bulk_operation.file.attach(valid_file.open)
      expect(bulk_operation).to be_valid
    end

    it "does not allow empty file" do
      bulk_operation.file.attach(empty_file.open)
      expect(bulk_operation).to have_error(:file, :empty, "Uploaded file is empty")
    end

    it "does not allow a file with only headers" do
      bulk_operation.file.attach(only_headers_file.open)
      expect(bulk_operation).to have_error(:file, :empty, "Uploaded file is empty")
    end

    it "does not allow file with no header" do
      bulk_operation.file.attach(no_header_file.open)
      expect(bulk_operation).to have_error(:file, :invalid, "Uploaded file is wrong format")
    end

    it "does not allow malformed CSV" do
      bulk_operation.file.attach(malformed_csv_file.open)
      expect(bulk_operation).to have_error(:file, "Unclosed quoted field in line 1.")
    end

    it "does not allow a file with invalid headers" do
      bulk_operation.file.attach(invalid_header_file.open)
      expect(bulk_operation).to have_error(:file, :invalid, "Uploaded file is wrong format")
    end

    it "allows a file with extra columns" do
      bulk_operation.file.attach(valid_file_extra_columns.open)
      expect(bulk_operation).to be_valid
    end

    it "allows a file with whitespace in headers" do
      bulk_operation.file.attach(valid_file_whitespace_in_headers.open)
      expect(bulk_operation).to be_valid
    end

    context "when the file contains characters with ISO-8859-1 encoding" do
      subject(:bulk_operation) { BulkOperation::UploadEligibilityList::DisadvantagedEarlyYearsSchool.new(admin:) }

      it "allows a valid file" do
        file = File.open(Rails.root.join("spec/fixtures/files/disadvantaged_ey_eligibility_list_iso_8859_1_encoding.csv"))
        bulk_operation.file.attach(file)
        expect(bulk_operation).to be_valid
      end
    end
  end

  describe "#run!" do
    subject { bulk_operation.run! }

    before do
      bulk_operation.file.attach(file)
      bulk_operation.save!
      create(:eligibility_list_entry, :pp50_school, identifier: "200000")
      create(:eligibility_list_entry, :pp50_school, identifier: "300000")
    end

    let(:urn) { "100001" }
    let(:file) { tempfile_with_bom("#{EligibilityList::Pp50School::IDENTIFIER_CSV_HEADERS.first},other\n #{urn} ,whatever\n").open }
    let(:bulk_operation) { build(:upload_eligibility_list_bulk_operation) }

    it "deletes existing records for that eligibility list type" do
      expect { subject }.to change(EligibilityList::Pp50School, :count).from(2).to(1)
    end

    it "creates new records from the uploaded file" do
      expect { subject }.to change {
        EligibilityList::Pp50School.where(identifier: urn, identifier_type: EligibilityList::Pp50School::IDENTIFIER_TYPE).count
      }.from(0).to(1)
    end

    context "when there are characters with ISO-8859-1 encoding" do
      let(:bulk_operation) { BulkOperation::UploadEligibilityList::DisadvantagedEarlyYearsSchool.new(admin:) }
      let(:file) { File.open(Rails.root.join("spec/fixtures/files/disadvantaged_ey_eligibility_list_iso_8859_1_encoding.csv")) }
      let(:urn) { "107747" } # value from the fixture file

      it "creates new records correctly" do
        subject
        expect(bulk_operation).to be_valid
        expect(EligibilityList::DisadvantagedEarlyYearsSchool.where(identifier: urn, identifier_type: :urn).count).to eq 1
      end
    end

    context "when there are rows in the CSV with the same identifier" do
      let(:bulk_operation) { BulkOperation::UploadEligibilityList::DisadvantagedEarlyYearsSchool.new(admin:) }
      let(:file) { tempfile_with_bom("#{EligibilityList::DisadvantagedEarlyYearsSchool::IDENTIFIER_CSV_HEADERS.join(',')}\n#{urn} , \n900001 ,#{urn} ").open }

      it "ignores duplicates" do
        subject
        expect(EligibilityList::DisadvantagedEarlyYearsSchool.where(identifier: urn, identifier_type: :urn).count).to eq 1
      end
    end

    context "when the eligibility list type has multiple identifier columns (DisadvantagedEarlyYearsSchool)" do
      let(:bulk_operation) { BulkOperation::UploadEligibilityList::DisadvantagedEarlyYearsSchool.new(admin:) }
      let(:file) { tempfile_with_bom("#{EligibilityList::DisadvantagedEarlyYearsSchool::IDENTIFIER_CSV_HEADERS.join(',')},other\n#{urn} , ,whatever\n100001 ,#{ofsted_urn} ,whatever").open }
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
