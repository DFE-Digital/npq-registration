require "rails_helper"

RSpec.describe Statements::MarkAsPayable do
  let(:application) { create(:application, :eligible_for_funded_place) }
  let(:lead_provider) { application.lead_provider }
  let(:statement) { create(:statement, :next_output_fee, lead_provider:) }
  let!(:declaration) { create(:declaration, :submitted_or_eligible, lead_provider:, application:) }
  let!(:voided_declaration) { create(:declaration, :voided, lead_provider:) }

  subject { described_class.new(statement:) }

  before do
    create(:statement_item, :eligible, statement:, declaration:)
    create(:statement_item, :eligible, statement:)
    create(:statement_item, :eligible, statement:)
    create(:statement_item, :voided, statement:, declaration: voided_declaration)
    create(:statement_item, :voided, statement:)
    create(:statement_item, :voided, statement:)
  end

  describe "#mark" do
    let(:mock_declarations_mark_as_payable_service) { instance_double(Declarations::MarkAsPayable) }

    before do
      allow(Declarations::MarkAsPayable).to receive(:new).with(statement:).and_return(mock_declarations_mark_as_payable_service)
      allow(mock_declarations_mark_as_payable_service).to receive(:mark).with(declaration:)
    end

    it "transitions the statement state itself" do
      expect {
        subject.mark
        statement.reload
      }.to change(statement, :state).from("open").to("payable")
    end

    it "calls Declarations::MarkAsPayable service with correct params" do
      subject.mark

      expect(Declarations::MarkAsPayable).to have_received(:new).with(statement:)
      expect(mock_declarations_mark_as_payable_service).to have_received(:mark).with(declaration:)
      expect(mock_declarations_mark_as_payable_service).not_to have_received(:mark).with(declaration: voided_declaration)
    end
  end
end
