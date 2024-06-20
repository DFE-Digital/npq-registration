# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::DeclarationsCsvSerializer, type: :serializer do
  let(:view) { :v1 }
  let(:instance) { described_class.new(declarations, view:) }

  describe "#serialize" do
    subject(:csv) { instance.serialize }

    let(:declarations) { create_list(:declaration, 2) }
    let(:rows) { CSV.parse(csv, headers: true) }
    let(:first_declaration) { declarations.first }
    let(:first_row) { rows.first.to_hash.symbolize_keys }

    it { expect(rows.count).to eq(declarations.count) }
    it { expect(first_row.values).to all(be_present) }

    it "returns expected data", :aggregate_failures do
      expect(first_row).to include({
        id: first_declaration.ecf_id,
        participant_id: first_declaration.user.ecf_id,
        declaration_type: first_declaration.declaration_type,
        course_identifier: first_declaration.course_identifier,
        declaration_date: first_declaration.declaration_date.rfc3339,
        updated_at: first_declaration.updated_at.rfc3339,
        state: first_declaration.state,
        has_passed: "TODO",
        voided: first_declaration.voided_state?.to_s,
        eligible_for_payment: first_declaration.eligible_for_payment?.to_s,
      })

      expect(first_row).not_to have_key("type")
    end

    it "calls the DeclarationSerializer with the correct view" do
      expect(API::DeclarationSerializer).to receive(:render).with(declarations, view:).and_call_original

      csv
    end

    context "when there are no declarations" do
      let(:declarations) { [] }

      it { expect(csv).to be_nil }
    end
  end
end
