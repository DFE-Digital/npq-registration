require "rails_helper"

RSpec.describe BulkOperation::UpdateAndVerifyTrns, type: :model do
  let(:valid_file) do
    tempfile <<~CSV
      User ID,Updated TRN
      f43cbfc0-33f1-44e0-85d5-93d6fa12cdf3,1234567
    CSV
  end

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

    let(:only_headers_file) do
      tempfile <<~CSV
        User ID,Updated TRN
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

    it "does not allow a file with only headers" do
      bulk_operation.file.attach(only_headers_file.open)
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

  describe "#ids_to_update" do
    subject(:ids_to_update) { bulk_operation.ids_to_update }

    let(:bulk_operation) { create(:update_and_verify_trns_bulk_operation, trns_to_update: [%w[f43cbfc0-33f1-44e0-85d5-93d6fa12cdf3 1234567]]) }

    it "returns a CSV::Table object" do
      expect(ids_to_update).to be_a(CSV::Table)
      expect(ids_to_update.to_a).to eq [["User ID", "Updated TRN"], %w[f43cbfc0-33f1-44e0-85d5-93d6fa12cdf3 1234567]]
    end
  end
end
