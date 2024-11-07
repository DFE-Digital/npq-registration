# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::PaymentAuthorisationForm, type: :model do
  subject(:form) { described_class.new(statement, params) }

  let(:statement) { create :statement }
  let(:params) { { checks_done: true } }

  describe "#valid?" do
    context "when checks_done is true" do
      it { is_expected.to be_valid }
    end

    context "when checks_done is false" do
      let(:params) { { checks_done: false } }

      it { is_expected.not_to be_valid }

      it "sets the error" do
        expect(form.tap(&:valid?).errors.messages)
          .to include(checks_done: include(/Confirm all/))
      end
    end

    context "when checks_done is nil" do
      let(:params) { {} }

      it { is_expected.not_to be_valid }

      it "sets the error" do
        expect(form.tap(&:valid?).errors.messages)
          .to include(checks_done: include(/Confirm all/))
      end
    end
  end

  describe "#save_form" do
    it "marks statement as paid" do
      expect { form.save_form }.to change(statement, :marked_as_paid_at)
    end

    it "calls the correct service class" do
      expect(Statements::MarkAsPaidJob).to receive(:perform_later).with(statement_id: statement.id)

      form.save_form
    end
  end
end
