require "rails_helper"

RSpec.describe BulkOperation, type: :model do
  describe "validations" do
    let(:admin) { create(:admin) }
    let(:empty_file) { Tempfile.new }

    let(:wrong_format_file) do
      tempfile <<~CSV
        one,two
        three,four
      CSV
    end

    let(:valid_file) do
      tempfile <<~CSV
        #{SecureRandom.uuid}
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

    it "does not allow malformed CSV" do
      bulk_operation.file.attach(malformed_csv_file.open)
      expect(bulk_operation).not_to be_valid
    end
  end

  describe "scopes" do
    describe "not_started" do
      let(:started_bulk_operation) { create(:reject_applications_bulk_operation, started_at: Time.zone.yesterday) }
      let(:not_started_bulk_operation) { create(:reject_applications_bulk_operation, started_at: nil) }

      it "returns not started bulk opeartions" do
        expect(BulkOperation.not_started).to eq [not_started_bulk_operation]
      end
    end
  end

  describe "#started?" do
    context "when started_at present" do
      let(:bulk_operation) { build(:reject_applications_bulk_operation, started_at: Time.zone.yesterday) }

      it "returns true" do
        expect(bulk_operation.started?).to be true
      end
    end

    context "when started_at not present" do
      let(:bulk_operation) { create(:reject_applications_bulk_operation, started_at: nil) }

      it "returns false" do
        expect(bulk_operation.started?).to be false
      end
    end
  end
end
