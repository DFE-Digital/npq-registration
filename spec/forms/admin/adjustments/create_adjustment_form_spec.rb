# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Adjustments::CreateAdjustmentForm, type: :model do
  subject(:form) { described_class.new(created_adjustment_ids:, statement:, description:, amount:) }

  let(:created_adjustment_ids) { nil }
  let(:statement) { create(:statement) }
  let(:description) { nil }
  let(:amount) { nil }

  describe "#save_form" do
    subject(:save_form) { form.save_form }

    context "when the adjustment is valid" do
      let(:description) { "Adjustment description" }
      let(:amount) { 100 }

      it "saves the adjustment" do
        expect { save_form }.to change(statement.adjustments, :count).by(1)
      end

      it "adds the adjustment ID to the created_adjustment_ids" do
        save_form
        expect(form.created_adjustment_ids).to include(Adjustment.last.id)
      end

      it "returns true" do
        expect(save_form).to be true
      end

      it "the form should be valid" do
        expect(form).to be_valid
      end
    end

    context "when the adjustment is invalid" do
      it "does not save the adjustment" do
        expect { save_form }.not_to change(statement.adjustments, :count)
      end

      it "returns false" do
        expect(save_form).to be false
      end

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

    context "when the statement is payable" do
      let(:statement) { create(:statement, :payable) }

      it "does not save the adjustment" do
        expect { save_form }.not_to change(statement.adjustments, :count)
      end

      it "returns false" do
        expect(save_form).to be false
      end

      it "the form should not be valid" do
        expect(form).not_to be_valid
      end

      it "sets the errors from the adjustment" do
        form.valid?

        expect(form.errors.messages).to include(
          statement: ["The statement has to be open for adjustments to be made"],
        )
      end
    end

    context "when the statement is paid" do
      let(:statement) { create(:statement, :paid) }

      it "does not save the adjustment" do
        expect { save_form }.not_to change(statement.adjustments, :count)
      end

      it "returns false" do
        expect(save_form).to be false
      end

      it "the form should not be valid" do
        expect(form).not_to be_valid
      end

      it "sets the errors from the adjustment" do
        form.valid?

        expect(form.errors.messages).to include(
          statement: ["The statement has to be open for adjustments to be made"],
        )
      end
    end
  end
end
