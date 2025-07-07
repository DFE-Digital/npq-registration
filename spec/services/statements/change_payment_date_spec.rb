# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::ChangePaymentDate, type: :model do
  subject(:service) { described_class.new(statement:, payment_date:) }

  let(:statement) { create(:statement) }
  let(:payment_date) { statement.deadline_date }

  describe "validations" do
    it "does not allow a blank payment date" do
      expect(subject).to validate_presence_of(:payment_date).with_message(:blank)
    end

    it "does not allow a nil statement" do
      expect(subject).not_to allow_value(nil).for(:statement).with_message("Statement not found")
    end
  end

  describe "#change" do
    subject { described_class.new(statement:, payment_date:).change }

    it "returns true" do
      expect(subject).to be true
    end

    it "changes the payment date of the statement" do
      expect { subject }.to change { statement.reload.payment_date }.to(statement.deadline_date)
    end

    context "when the payment date is before the deadline date" do
      let(:payment_date) { statement.deadline_date - 1.day }

      it "returns false" do
        expect(subject).to be false
      end

      it "has an error on payment_date" do
        expect(service).to have_error(:payment_date, :invalid, "Output payment date cannot be before the Output payment deadline")
      end

      it "does not change the payment date" do
        expect { subject }.not_to(change { statement.reload.payment_date })
      end
    end

    context "when there is no deadline date" do
      let(:statement) { create(:statement, deadline_date: nil) }
      let(:payment_date) { Date.current }

      it "returns true" do
        expect(subject).to be true
      end

      it "changes the payment date of the statement" do
        expect { subject }.to change { statement.reload.payment_date }.to(payment_date)
      end
    end
  end
end
