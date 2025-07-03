# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Adjustments::CreateAdjustmentForm, type: :model do
  let(:form) { described_class.new(created_adjustment_ids:, statement:, description:, amount:) }

  let(:created_adjustment_ids) { nil }
  let(:statement) { create(:statement) }
  let(:description) { "Adjustment description" }
  let(:amount) { 100 }

  describe "#save_adjustment" do
    subject(:save_adjustment) { form.save_adjustment }

    shared_examples "saving an adjustment" do
      it "saves the adjustment" do
        expect { save_adjustment }.to change(statement.adjustments, :count).by(1)
      end

      it "adds the adjustment ID to the created_adjustment_ids" do
        save_adjustment
        expect(form.created_adjustment_ids).to include(Adjustment.last.id)
      end

      it { is_expected.to be true }

      it "the form should be valid" do
        expect(form).to be_valid
      end
    end

    shared_examples "not saving an adjustment" do
      it { is_expected.to be false }

      it "the form should not be valid" do
        expect(form).not_to be_valid
      end

      it "sets the errors from the adjustment" do
        form.valid?

        expect(form.errors.messages).to include(
          statement: ["Adjustments can no longer be made to this statement, as it is marked as paid"],
        )
      end
    end

    context "when the adjustment is invalid" do
      let(:description) { nil }
      let(:amount) { nil }

      it "does not save the adjustment" do
        expect { save_adjustment }.not_to change(statement.adjustments, :count)
      end

      it { is_expected.to be false }

      it "the form should not be valid" do
        expect(form).not_to be_valid
      end

      it "sets the errors from the adjustment" do
        form.valid?

        expect(form.errors.messages).to include(
          description: ["You must enter a description for the adjustment"],
          amount: ["You must enter an adjustment amount"],
        )
      end
    end

    context "when the statement is open" do
      it_behaves_like "saving an adjustment"
    end

    context "when the statement is payable" do
      let(:statement) { create(:statement, :payable) }

      it_behaves_like "saving an adjustment"
    end

    context "when the statement is paid, but does not have marked_as_paid_at set" do
      let(:statement) { create(:statement, :paid, marked_as_paid_at: nil) }

      it_behaves_like "not saving an adjustment"
    end

    context "when the statement is marked as paid" do
      let(:statement) { create(:statement, :paid, marked_as_paid_at: Time.zone.now) }

      it_behaves_like "not saving an adjustment"
    end
  end
end
