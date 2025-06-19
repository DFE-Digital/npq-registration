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

    let(:bulk_operation) { create(:update_and_verify_trns_bulk_operation) }
    let(:file) do
      tempfile(
        "#{BulkOperation::UpdateAndVerifyTrns::FILE_HEADERS.join(",")}\n" \
        "f43cbfc0-33f1-44e0-85d5-93d6fa12cdf3,1234567\n",
      )
    end

    before { bulk_operation.file.attach(file.open) }

    it "returns a CSV::Table object" do
      expect(ids_to_update).to be_a(CSV::Table)
      expect(ids_to_update.to_a).to eq [["User ID", "Updated TRN"], %w[f43cbfc0-33f1-44e0-85d5-93d6fa12cdf3 1234567]]
    end
  end

  describe "#run!" do
    let(:trns_to_update) { [[user1.ecf_id, "1234567"], [user2.ecf_id, "2345678"]] }
    let(:bulk_operation) { create(:update_and_verify_trns_bulk_operation, admin: create(:admin)) }
    let(:instance) { described_class.new(bulk_operation:) }
    let(:user1) { create(:user, trn: "1000000") }
    let(:user2) { create(:user, trn: "1000001") }
    let(:file) do
      tempfile(
        "#{BulkOperation::UpdateAndVerifyTrns::FILE_HEADERS.join(",")}\n" \
        "#{trns_to_update.map { |ecf_id, trn| "#{ecf_id},#{trn}" }.join("\n")}" \
        "\n",
      )
    end

    before { bulk_operation.file.attach(file.open) }

    subject(:run) { bulk_operation.run! }

    it "updates the TRNs and trn_verifed" do
      expect { run }.to change { user1.reload.trn }.to("1234567")
        .and change { user1.reload.trn_verified }.to(true)
        .and change { user2.reload.trn }.to("2345678")
        .and change { user2.reload.trn_verified }.to(true)
    end

    it "saves the result" do
      run
      expect(JSON.parse(bulk_operation.result)[user1.ecf_id]).to match("TRN updated and verified")
      expect(JSON.parse(bulk_operation.result)[user2.ecf_id]).to match("TRN updated and verified")
    end

    it "sets finished_at" do
      subject
      expect(bulk_operation.reload.finished_at).to be_present
    end

    context "when there is a validation error" do
      let(:trns_to_update) { [[user1.ecf_id, "0000000"]] }

      it "does not update the TRN" do
        expect { run }.not_to(change { user1.reload.trn })
      end

      it "saves the result" do
        run
        expect(JSON.parse(bulk_operation.result)[user1.ecf_id]).to match("You must enter a valid TRN")
      end
    end

    context "when the user does not exist" do
      let(:user_ecf_id) { SecureRandom.uuid }
      let(:trns_to_update) { [[user_ecf_id, "1234567"]] }

      it { expect(run[user_ecf_id]).to match("User not found") }
    end

    context "when the user ecf_id is not a valid UUID" do
      let(:user_ecf_id) { "invalid-uuid" }
      let(:trns_to_update) { [[user_ecf_id, "1234567"]] }

      it { expect(run[user_ecf_id]).to match("User not found") }
    end
  end
end
