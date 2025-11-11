require "rails_helper"

RSpec.describe BulkOperation::BackfillDeclarationDeliveryPartners, type: :model do
  subject(:bulk_operation) { described_class.new(admin:) }

  let(:valid_file) do
    tempfile <<~CSV
      Declaration ID,Primary Delivery Partner ID,Secondary Delivery Partner ID
      a99d373d-0ca6-4153-a9a2-38aec8cb9c41,dad2badb-0823-4412-b1a9-508a6918506e,
      720be8f3-76ed-4f91-842d-fd7664078540,bcedf334-1484-4509-af4f-80f7f386d4cf,563c1e1a-4365-4099-8f1d-d9411a31fe8e
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
        one,two,three
      CSV
    end

    let(:only_headers_file) do
      tempfile <<~CSV
        Declaration ID,Primary Delivery Partner ID,Secondary Delivery Partner ID
      CSV
    end

    let(:malformed_csv_file) do
      tempfile <<~CSV
        unclosed"quotation
      CSV
    end

    let(:headers_in_different_order) do
      tempfile <<~CSV
        Primary Delivery Partner ID,Secondary Delivery Partner ID,Declaration ID
        dad2badb-0823-4412-b1a9-508a6918506e,,a99d373d-0ca6-4153-a9a2-38aec8cb9c41
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

    it "allows headers in different order" do
      bulk_operation.file.attach(headers_in_different_order.open)
      expect(bulk_operation).to be_valid
    end
  end

  describe "#run!" do
    let(:lead_provider) { LeadProvider.first }
    let(:cohort) { create(:cohort, start_year: 2023) }
    let(:bulk_operation) { create(:backfill_declaration_delivery_partners_bulk_operation, admin: create(:admin)) }
    let(:instance) { described_class.new(bulk_operation:) }
    let(:declaration_1) { create(:declaration, lead_provider:, cohort:, delivery_partner: nil) }
    let(:declaration_2) { create(:declaration, lead_provider:, cohort:, delivery_partner: nil) }
    let(:delivery_partner_1) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    let(:delivery_partner_2) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    let(:delivery_partner_3) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    let(:file) do
      tempfile(
        "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
        "#{declaration_1.ecf_id},#{delivery_partner_1.ecf_id},\n" \
        "#{declaration_2.ecf_id},#{delivery_partner_2.ecf_id},#{delivery_partner_3.ecf_id}\n",
      )
    end

    before { bulk_operation.file.attach(file.open) }

    subject(:run) { bulk_operation.run! }

    it "updates the declarations" do
      expect { run }.to change { declaration_1.reload.delivery_partner }.to(delivery_partner_1)
        .and change { declaration_2.reload.delivery_partner }.to(delivery_partner_2)
        .and change { declaration_2.reload.secondary_delivery_partner }.to(delivery_partner_3)
    end

    it "saves the result" do
      run
      expect(JSON.parse(bulk_operation.result)[declaration_1.ecf_id]).to match("Declaration updated")
      expect(JSON.parse(bulk_operation.result)[declaration_2.ecf_id]).to match("Declaration updated")
    end

    it "sets finished_at" do
      subject
      expect(bulk_operation.reload.finished_at).to be_present
    end

    context "when updating only the secondary delivery partner" do
      let(:declaration_1) { create(:declaration, lead_provider:, cohort:, delivery_partner: delivery_partner_1) }

      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},#{delivery_partner_1.ecf_id},#{delivery_partner_3.ecf_id}\n",
        )
      end

      it "updates the declaration" do
        expect { run }.to change { declaration_1.reload.secondary_delivery_partner }.to(delivery_partner_3)
      end
    end

    context "when the secondary delivery partner is #N/A" do
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},#{delivery_partner_1.ecf_id},#N/A\n",
        )
      end

      it { expect(run[declaration_1.ecf_id]).to match("Declaration updated") }
    end

    context "when the declaration already has a delivery partner" do
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},#{delivery_partner_1.ecf_id},\n",
        )
      end

      let(:declaration_1) { create(:declaration, cohort:, delivery_partner: delivery_partner_3) }

      it "does not change the delivery partner" do
        expect { run }.not_to(change { declaration_1.reload.delivery_partner })
      end

      it { expect(run[declaration_1.ecf_id]).to match("Declaration already has delivery partner") }
    end

    context "when the declaration already has a secondary delivery partner" do
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},#{delivery_partner_1.ecf_id},#{delivery_partner_3.ecf_id}\n",
        )
      end

      let(:declaration_1) { create(:declaration, cohort:, delivery_partner: delivery_partner_1, secondary_delivery_partner: delivery_partner_2) }

      it "does not change the delivery partner" do
        expect { run }.not_to(change { declaration_1.reload.secondary_delivery_partner })
      end

      it { expect(run[declaration_1.ecf_id]).to match("Declaration already has secondary delivery partner") }
    end

    context "when the declaration does not exist" do
      let(:declaration_ecf_id) { SecureRandom.uuid }
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_ecf_id},#{delivery_partner_1.ecf_id},\n",
        )
      end

      it { expect(run[declaration_ecf_id]).to match("Declaration not found") }
    end

    context "when the declaration ecf_id is not a valid UUID" do
      let(:declaration_ecf_id) { "invalid-uuid" }
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_ecf_id},#{delivery_partner_1.ecf_id},\n",
        )
      end

      it { expect(run[declaration_ecf_id]).to match("Declaration not found") }
    end

    context "when the delivery partner does not exist" do
      let(:delivery_partner_id) { SecureRandom.uuid }
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},#{delivery_partner_id},\n",
        )
      end

      it { expect(run[declaration_1.ecf_id]).to match("Primary Delivery Partner not found: ID:#{delivery_partner_id}") }
    end

    context "when the delivery partner ecf_id is not a valid UUID" do
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},rubbish,\n",
        )
      end

      it { expect(run[declaration_1.ecf_id]).to match("Primary Delivery Partner not found: ID:rubbish") }
    end

    context "when the secondary delivery partner does not exist" do
      let(:delivery_partner_id) { SecureRandom.uuid }
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},#{delivery_partner_1.ecf_id},#{delivery_partner_id}\n",
        )
      end

      it { expect(run[declaration_1.ecf_id]).to match("Secondary Delivery Partner not found: ID:#{delivery_partner_id}") }
    end

    context "when the secondary delivery partner ecf_id is not a valid UUID" do
      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},#{delivery_partner_1.ecf_id},rubbish\n",
        )
      end

      it { expect(run[declaration_1.ecf_id]).to match("Secondary Delivery Partner not found: ID:rubbish") }
    end

    context "when there is an error updating a declaration" do
      let(:delivery_partner_for_wrong_lead_provider) { create(:delivery_partner, lead_providers: { cohort => create(:lead_provider) }) }

      let(:file) do
        tempfile(
          "#{BulkOperation::BackfillDeclarationDeliveryPartners::FILE_HEADERS.join(",")}\n" \
          "#{declaration_1.ecf_id},#{delivery_partner_for_wrong_lead_provider.ecf_id},\n",
        )
      end

      it { expect(run[declaration_1.ecf_id]).to match("The entered '#/delivery_partner_id' is not from your list of confirmed Delivery Partners for the Cohort") }
    end
  end
end
