# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::DeclarationsCsvSerializer, type: :serializer do
  let(:instance) { described_class.new(declarations) }

  describe "#serialize" do
    subject(:csv) { instance.serialize }

    let(:declarations) { create_list(:declaration, 2, :started) }
    let(:rows) { CSV.parse(csv, headers: true) }
    let(:first_declaration) { declarations.first }
    let(:first_row) { rows.first.to_hash.symbolize_keys }

    it { expect(rows.count).to eq(declarations.count) }
    it { expect(first_row.except(:has_passed, :statement_id, :clawback_statement_id, :ineligible_for_funding_reason, :delivery_partner_id, :delivery_partner_name, :secondary_delivery_partner_id, :secondary_delivery_partner_name).values).to all(be_present) }

    it "returns expected data", :aggregate_failures do
      expect(first_row).to include({
        id: first_declaration.ecf_id,
        participant_id: first_declaration.user.ecf_id,
        declaration_type: first_declaration.declaration_type,
        course_identifier: first_declaration.course_identifier,
        declaration_date: first_declaration.declaration_date.rfc3339,
        updated_at: first_declaration.updated_at.rfc3339,
        created_at: first_declaration.created_at.rfc3339,
        state: first_declaration.state,
        has_passed: nil,
        application_id: first_declaration.application.ecf_id,
        lead_provider_name: first_declaration.lead_provider.name,
        uplift_paid: first_declaration.uplift_paid?.to_s,
      })

      expect(first_row).not_to have_key("type")
    end

    it "calls the DeclarationSerializer" do
      expect(API::DeclarationSerializer).to receive(:render).with(declarations).and_call_original

      csv
    end

    context "when there are no declarations" do
      let(:declarations) { [] }

      it { expect(csv).to be_nil }
    end
  end
end
