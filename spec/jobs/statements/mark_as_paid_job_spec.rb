# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::MarkAsPaidJob do
  subject(:job) { described_class.new.perform(statement_id:) }

  before do
    allow(Statements::MarkAsPaid).to receive(:new).with(statement).and_return(service)
    allow(service).to receive(:mark).and_return(true)
    allow(Rails.logger).to receive(:warn)

    job
  end

  let(:service) { Statements::MarkAsPaid.new(statement) }
  let(:statement) { create(:statement, :payable) }
  let(:statement_id) { statement.id }

  context "with correct params" do
    context "when statement is payable" do
      it "calls the correct service" do
        expect(service).to have_received(:mark)
      end
    end

    context "when statement is not payable" do
      let(:statement) { create(:statement, :paid) }

      it "does not call the service" do
        expect(Statements::MarkAsPaid).not_to have_received(:new)
      end
    end
  end

  context "with incorrect params" do
    let(:statement_id) { SecureRandom.uuid }

    it "does not call the service" do
      expect(Statements::MarkAsPaid).not_to have_received(:new)
    end

    it "logs a warning" do
      expect(Rails.logger)
        .to have_received(:warn)
            .with("Statement could not be found - statement_id: #{statement_id}")
    end
  end

  context "with no params" do
    let(:statement_id) { nil }

    it { is_expected.to be_nil }
  end
end
