# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Adjustments::CreateAdjustmentForm, type: :model do
  subject(:form) { described_class.new(session:, statement:, description:, amount:) }

  let(:session) { {} }
  let(:statement) { create(:statement) }
  let(:description) { nil }
  let(:amount) { nil }

  describe "#save" do
    context "when the adjustment is valid" do
      let(:description) { "Adjustment description" }
      let(:amount) { 100 }

      it "saves the adjustment" do
        expect { form.save }.to change(statement.adjustments, :count).by(1)
      end

      it "adds the adjustment ID to the session" do
        form.save # rubocop:disable Rails/SaveBang
        expect(session[:created_adjustment_ids]).to include(Adjustment.last.id)
      end

      it "returns true" do
        expect(form.save).to be true
      end

      it "the form should be valid" do
        expect(form).to be_valid
      end
    end

    context "when the adjustment is invalid" do
      it "does not save the adjustment" do
        expect { form.save }.not_to change(statement.adjustments, :count)
      end

      it "returns false" do
        expect(form.save).to be false
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
        expect { form.save }.not_to change(statement.adjustments, :count)
      end

      it "returns false" do
        expect(form.save).to be false
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
        expect { form.save }.not_to change(statement.adjustments, :count)
      end

      it "returns false" do
        expect(form.save).to be false
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
