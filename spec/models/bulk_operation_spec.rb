require "rails_helper"

RSpec.describe BulkOperation, type: :model do
  describe "validations" do
    let(:admin) { create(:admin) }
    let(:empty_file) { Tempfile.new }
    let(:wrong_format_file) do
      Tempfile.new.tap do |file|
        file.write "one,two\nthree,four\n"
        file.rewind
      end
    end
    let(:valid_file) do
      Tempfile.new.tap do |file|
        file.write "#{SecureRandom.uuid}\n"
        file.rewind
      end
    end

    it "allows a valid file" do
      bulk_operation = described_class.new(admin:)
      bulk_operation.file.attach(valid_file.open)
      expect(bulk_operation).to be_valid
    end

    it "does not allow empty file" do
      bulk_operation = described_class.new
      bulk_operation.file.attach(empty_file.open)
      expect(bulk_operation).not_to be_valid
    end

    it "does not allow file with wrong format" do
      bulk_operation = described_class.new
      bulk_operation.file.attach(wrong_format_file.open)
      expect(bulk_operation).not_to be_valid
    end
  end
end
