require "rails_helper"

RSpec.describe Crons::BatchSendLatestOutcomesJob, type: :job do
  let(:outcome_1) { instance_double(ParticipantOutcome, id: 1) }
  let(:outcome_2) { instance_double(ParticipantOutcome, id: 2) }
  let(:outcomes) { [outcome_1, outcome_2] }

  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    allow(ParticipantOutcome).to receive(:to_send_to_qualified_teachers_api).and_return(outcomes)
  end

  describe "#perform" do
    subject(:job) { described_class.new.perform(batch_size) }

    before { job }

    context "when there are no more than batch_size records" do
      let(:batch_size) { 2 }

      it "enqueues the send job for each record" do
        expect(SendToQualifiedTeachersAPIJob).to(have_been_enqueued.exactly(:once).with(participant_outcome_id: 1).on_queue("participant_outcomes"))
        expect(SendToQualifiedTeachersAPIJob).to(have_been_enqueued.exactly(:once).with(participant_outcome_id: 2).on_queue("participant_outcomes"))
      end
    end

    context "when there are more than batch_size records" do
      let(:batch_size) { 1 }

      it "only enqueues the send job for the first records up to the batch_size" do
        expect(SendToQualifiedTeachersAPIJob).to have_been_enqueued.exactly(:once).with(participant_outcome_id: 1).on_queue("participant_outcomes")
        expect(SendToQualifiedTeachersAPIJob).not_to have_been_enqueued.with(participant_outcome_id: 2)
      end
    end
  end

  describe "#perform_later" do
    subject(:job) { described_class.perform_later }

    before do
      allow(SendToQualifiedTeachersAPIJob).to receive(:perform_later).and_return(true)
      allow(Rails.logger).to receive(:warn)
      allow(Sentry).to receive(:capture_exception).and_return(true)
    end

    it "enqueues the job exactly once" do
      expect { job }.to have_enqueued_job(described_class).exactly(:once).on_queue("participant_outcomes")
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
        allow(SendToQualifiedTeachersAPIJob).to receive(:perform_later).and_raise(ActiveRecord::RecordInvalid)

        perform_enqueued_jobs { job }
      end

      it { expect(Sentry).to have_received(:capture_exception) }
      it { expect(Delayed::Job.count).to be_zero }
    end
  end
end
