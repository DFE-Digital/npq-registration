# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::ChangeDeadlineDate, type: :model do
  subject(:service) { described_class.new(statement:, deadline_date:) }

  let(:statement) { create(:statement) }
  let(:deadline_date) { statement.payment_date }

  describe "validations" do
    it "does not allow a blank deadline date" do
      expect(subject).to validate_presence_of(:deadline_date).with_message(:blank)
    end

    it "does not allow a nil statement" do
      expect(subject).not_to allow_value(nil).for(:statement).with_message("Statement not found")
    end
  end

  describe "#change" do
    subject { described_class.new(statement:, deadline_date:).change }

    it "returns true" do
      expect(subject).to be true
    end

    it "changes the deadline date of the statement" do
      expect { subject }.to change { statement.reload.deadline_date }.to(statement.payment_date)
    end

    context "when the deadline date is after the payment date" do
      let(:deadline_date) { statement.payment_date + 1.day }

      it "returns false" do
        expect(subject).to be false
      end

      it "has an error on deadline_date" do
        expect(service).to have_error(:deadline_date, :invalid, "Output payment deadline cannot be after the Output payment date")
      end

      it "does not change the deadline date" do
        expect { subject }.not_to(change { statement.reload.deadline_date })
      end
    end

    context "when there is no payment date" do
      let(:statement) { create(:statement, payment_date: nil) }
      let(:deadline_date) { Date.current }

      it "returns true" do
        expect(subject).to be true
      end

      it "changes the deadline date of the statement" do
        expect { subject }.to change { statement.reload.deadline_date }.to(deadline_date)
      end
    end
  end
end
