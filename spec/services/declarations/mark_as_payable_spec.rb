require "rails_helper"

RSpec.describe Declarations::MarkAsPayable do
  let(:application) { create(:application, :eligible_for_funded_place) }
  let(:lead_provider) { application.lead_provider }
  let(:statement) { create(:statement, :next_output_fee, lead_provider:) }
  let(:declaration) { create(:declaration, :submitted_or_eligible, lead_provider:, application:) }
  let!(:statement_item) { create(:statement_item, :eligible, statement:, declaration:) }
  let!(:another_declaration_statement_item) { create(:statement_item, :eligible, statement:) }

  subject { described_class.new(statement:) }

  describe "#mark" do
    it "transitions the declaration state itself" do
      expect {
        subject.mark(declaration:)
        declaration.reload
      }.to change(declaration, :state).from("eligible").to("payable")
    end

    it "transitions the correct statement item state" do
      expect {
        subject.mark(declaration:)
        statement_item.reload
        another_declaration_statement_item.reload
      }.to change(statement_item, :state).from("eligible").to("payable")
      .and(not_change { another_declaration_statement_item.state })
    end
  end
end
