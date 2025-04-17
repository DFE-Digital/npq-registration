require "rails_helper"

RSpec.describe BulkOperation::UpdateAndVerifyTrns, type: :model do
  describe "validations" do
    let(:admin) { create(:admin) }
    let(:empty_file) { Tempfile.new }

    let(:wrong_format_file) do
      tempfile <<~CSV
        one
        two
      CSV
    end

    let(:no_header_file) do
      tempfile <<~CSV
        one,two
        three,four
      CSV
    end

    let(:valid_file) do
      tempfile <<~CSV
        User ID,Updated TRN
        #{SecureRandom.uuid},1234567
      CSV
    end

    let(:malformed_csv_file) do
      tempfile <<~CSV
        unclosed"quotation
      CSV
    end

    subject(:bulk_operation) { described_class.new(admin:) }

    it "allows a valid file" do
      bulk_operation.file.attach(valid_file.open)
      expect(bulk_operation).to be_valid
    end

    it "does not allow empty file" do
      bulk_operation.file.attach(empty_file.open)
      expect(bulk_operation).not_to be_valid
    end

    it "does not allow file with wrong format" do
      bulk_operation.file.attach(wrong_format_file.open)
      expect(bulk_operation).not_to be_valid
    end

    it "does not allow file with no header" do
      bulk_operation.file.attach(no_header_file.open)
      expect(bulk_operation).not_to be_valid
    end

    it "does not allow malformed CSV" do
      bulk_operation.file.attach(malformed_csv_file.open)
      expect(bulk_operation).not_to be_valid
    end
  end
end
