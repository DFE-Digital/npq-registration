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

    context "when the statement is open" do
      it "returns true" do
        expect(destroy_adjustment).to be true
      end

      it "the form should be valid" do
        destroy_adjustment
        expect(form).to be_valid
      end

      it "destroys the adjustment" do
        expect { destroy_adjustment }.to change(statement.adjustments, :count).by(-1)
      end
    end

    context "when the statement is payable" do
      let(:statement) { create(:statement, :payable) }

      it "returns false" do
        expect(destroy_adjustment).to be false
      end

      it "the form should not be valid" do
        destroy_adjustment
        expect(form).not_to be_valid
      end

      it "does not destroy the adjustment" do
        expect { destroy_adjustment }.to(not_change { Adjustment.count })
      end

      it "sets the errors from the adjustment" do
        destroy_adjustment
        form.valid?

        expect(form.errors.messages).to include(
          statement: ["The statement has to be open for adjustments to be made"],
        )
      end
    end

    context "when the statement is paid" do
      let(:statement) { create(:statement, :paid) }

      it "returns false" do
        expect(destroy_adjustment).to be false
      end

      it "the form should not be valid" do
        destroy_adjustment
        expect(form).not_to be_valid
      end

      it "sets the errors from the adjustment" do
        destroy_adjustment
        form.valid?

        expect(form.errors.messages).to include(
          statement: ["The statement has to be open for adjustments to be made"],
        )
      end
    end
  end
end
