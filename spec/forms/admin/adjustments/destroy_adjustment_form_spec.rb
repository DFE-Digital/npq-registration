# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Adjustments::DestroyAdjustmentForm, type: :model do
  let(:form) { described_class.new(statement:, adjustment:) }

  let(:statement) { create(:statement) }
  let!(:adjustment) { create(:adjustment, statement:) }

  describe "#id" do
    it "returns the adjustment ID" do
      expect(form.id).to eq(adjustment.id)
    end
  end

  describe "#description" do
    it "returns the adjustment description" do
      expect(form.description).to eq(adjustment.description)
    end
  end

  describe "#amount" do
    it "returns the adjustment amount" do
      expect(form.amount).to eq(adjustment.amount)
    end
  end

  describe "#destroy_adjustment" do
    subject(:destroy_adjustment) { form.destroy_adjustment }

    shared_examples "destroying an adjustment" do
      it { is_expected.to be true }

      it "the form should be valid" do
        destroy_adjustment
        expect(form).to be_valid
      end

      it "destroys the adjustment" do
        expect { destroy_adjustment }.to change(statement.adjustments, :count).by(-1)
      end
    end

    context "when the statement is open" do
      it_behaves_like "destroying an adjustment"
    end

    context "when the statement is payable" do
      let(:statement) { create(:statement, :payable) }

      it_behaves_like "destroying an adjustment"
    end

    context "when the statement is paid" do
      let(:statement) { create(:statement, :paid) }

      it { is_expected.to be false }

      it "the form should not be valid" do
        destroy_adjustment
        expect(form).not_to be_valid
      end

      it "sets the errors from the adjustment" do
        destroy_adjustment
        form.valid?

        expect(form.errors.messages).to include(
          statement: ["Adjustments can no longer be made to this statement, as it is marked as paid"],
        )
      end
    end
  end
end
