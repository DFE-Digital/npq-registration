# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Adjustments::UpdateAdjustmentForm, type: :model do
  let(:form) { described_class.new(statement:, description:, amount:, adjustment:) }

  let(:statement) { create(:statement) }
  let(:adjustment) { create(:adjustment, statement:, description: "old description", amount: 200) }
  let(:description) { "new description" }
  let(:amount) { 400 }

  describe "#id" do
    it "returns the adjustment ID" do
      expect(form.id).to eq(adjustment.id)
    end
  end

  describe "#save_adjustment" do
    subject(:save_adjustment) { form.save_adjustment }

    shared_examples "updating an adjustment" do
      it "updates the adjustment description" do
        expect { save_adjustment }.to change { adjustment.reload.description }.from("old description").to("new description")
      end

      it "updates the adjustment amount" do
        expect { save_adjustment }.to change { adjustment.reload.amount }.from(200).to(400)
      end

      it { is_expected.to be true }

      it "the form should be valid" do
        expect(form).to be_valid
      end
    end

    context "when the adjustment is invalid" do
      let(:description) { "" }
      let(:amount) { nil }

      it { is_expected.to be false }

      it "the form should not be valid" do
        save_adjustment
        expect(form).not_to be_valid
      end

      it "sets the errors from the adjustment" do
        save_adjustment
        form.valid?

        expect(form.errors.messages).to include(
          description: ["You must enter a description for the adjustment"],
          amount: ["You must enter an adjustment amount"],
        )
      end
    end

    context "when the statement is open" do
      it_behaves_like "updating an adjustment"
    end

    context "when the statement is payable" do
      let(:statement) { create(:statement, :payable) }

      it_behaves_like "updating an adjustment"
    end

    context "when the statement is paid" do
      let(:statement) { create(:statement, :paid) }

      it { is_expected.to be false }

      it "the form should not be valid" do
        save_adjustment
        expect(form).not_to be_valid
      end

      it "sets the errors from the adjustment" do
        save_adjustment
        form.valid?

        expect(form.errors.messages).to include(
          statement: ["Adjustments can no longer be made to this statement, as it is marked as paid"],
        )
      end
    end
  end
end
