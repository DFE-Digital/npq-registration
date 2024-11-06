# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::MarkAsPaidJob, type: :job do
  subject(:job) { described_class.new.perform(statement_id:) }

  before do
    allow(Statements::MarkAsPaid).to receive(:new).with(statement).and_return(service)
    allow(service).to receive(:mark).and_return(true)
    allow(Rails.logger).to receive(:warn)
    allow(Sentry).to receive(:capture_exception).and_return(true)
  end

  let(:service) { Statements::MarkAsPaid.new(statement) }
  let(:statement) { create(:statement, :payable) }
  let(:statement_id) { statement.id }

  describe "#perform" do
    before { job }

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
              .with("Statement could not be found or is not payable - statement_id: #{statement_id}")
      end
    end

    context "with no params" do
      let(:statement_id) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#perform_later" do
    subject(:job) { described_class.perform_later(statement_id:) }

    it "enqueues the job exactly once" do
      expect { job }.to have_enqueued_job(described_class).exactly(:once).on_queue("default")
    end

    context "with valid job" do
      before do
        perform_enqueued_jobs { job }
      end

      it { expect(Sentry).not_to have_received(:capture_exception) }
      it { expect(Delayed::Job.count).to be_zero }
    end

    context "with invalid job" do
      before do
        allow(service).to receive(:mark).and_raise(exception)

        perform_enqueued_jobs { job }
      end

      let :exception do
        StateMachines::InvalidTransition.new(statement,
                                             Statement.state_machines[:state],
                                             :mark_paid)
      end

      it { expect(Sentry).to have_received(:capture_exception) }
      it { expect(Delayed::Job.count).to be_zero }
    end
  end
end
