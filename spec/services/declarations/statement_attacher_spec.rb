# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::StatementAttacher, type: :model do
  let(:statement) { create(:statement, :next_output_fee) }
  let(:declaration) { create(:declaration, :paid, lead_provider: statement.lead_provider, cohort: statement.cohort) }
  let(:instance) { described_class.new(declaration:) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:declaration) }

    context "when the next output fee statement does not exist" do
      before { statement.update!(output_fee: false) }

      it "adds an error to the declaration attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :declaration, type: :no_output_fee_statement)
      end
    end

    context "when the declaration is not in an attachable state" do
      before { declaration.update!(state: :submitted) }

      it "adds an error to the declaration attribute" do
        expect(instance).to be_invalid
        expect(instance.errors.first).to have_attributes(attribute: :declaration, type: :not_in_attachable_state)
      end
    end
  end

  describe "#attach" do
    subject(:attach) { instance.attach }

    it { is_expected.to be(true) }

    it "creates a statement item" do
      expect { attach }.to change { statement.reload.statement_items.count }.by(1)
      created_statement_item = statement.statement_items.last
      expect(created_statement_item).to have_attributes(declaration:, state: declaration.state)
    end

    context "when not valid" do
      let(:declaration) { nil }

      it { is_expected.to be(false) }
      it { expect { attach }.not_to(change { statement.reload.statement_items.count }) }
    end
  end
end
