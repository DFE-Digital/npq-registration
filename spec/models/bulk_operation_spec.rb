require "rails_helper"

RSpec.describe BulkOperation, type: :model do
  let(:admin) { create(:admin) }
  let(:application_ecf_id) { "e857f4bc-9e19-4bf8-9874-02a60905dbdb" }

  let(:valid_file) do
    tempfile <<~CSV
      #{application_ecf_id}
    CSV
  end

  describe "relationships" do
    it { is_expected.to belong_to(:admin) }
    it { is_expected.to belong_to(:ran_by_admin).class_name("Admin").optional }
    it { is_expected.to have_one_attached(:file) }
  end

  describe "validations" do
    subject(:bulk_operation) { described_class.new(admin:) }

    let(:empty_file) { Tempfile.new }

    let(:wrong_format_file) do
      tempfile <<~CSV
        one,two
        three,four
      CSV
    end

    let(:malformed_csv_file) do
      tempfile <<~CSV
        unclosed"quotation
      CSV
    end

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

  describe "callbacks" do
    subject(:bulk_operation) { build(:reject_applications_bulk_operation, admin:) }

    describe "before_save" do
      context "when file is attached" do
        before { bulk_operation.file.attach(valid_file.open) }

        it "updates the row_count" do
          expect { bulk_operation.save }.to change(bulk_operation, :row_count).from(nil).to(1)
        end
      end

      context "when file is not attached" do
        it "does not update the row_count" do
          expect { bulk_operation.save }.not_to change(bulk_operation, :row_count)
        end
      end
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

  describe "#finished?" do
    context "when finished_at present" do
      let(:bulk_operation) { build(:reject_applications_bulk_operation, finished_at: Time.zone.yesterday) }

      it "returns true" do
        expect(bulk_operation.finished?).to be true
      end
    end

    context "when finished_at not present" do
      let(:bulk_operation) { create(:reject_applications_bulk_operation, finished_at: nil) }

      it "returns false" do
        expect(bulk_operation.finished?).to be false
      end
    end
  end

  describe "#ids_to_update" do
    subject(:ids_to_update) { bulk_operation.ids_to_update }

    let(:bulk_operation) { create(:reject_applications_bulk_operation) }

    before { bulk_operation.file.attach(valid_file.open) }

    it "returns an array of application ECF IDs" do
      expect(ids_to_update.to_a).to eq [application_ecf_id]
    end
  end
end
