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
    context "when there are no more than batch_size records" do
      let(:batch_size) { 2 }

      it "enqueues the send job for each record" do
        described_class.perform_now(batch_size)

        expect(SendToQualifiedTeachersAPIJob).to(have_been_enqueued.exactly(:once).with(participant_outcome_id: 1).on_queue("participant_outcomes"))
        expect(SendToQualifiedTeachersAPIJob).to(have_been_enqueued.exactly(:once).with(participant_outcome_id: 2).on_queue("participant_outcomes"))
      end
    end

    context "when there are more than batch_size records" do
      let(:batch_size) { 1 }

      it "only enqueues the send job for the first records up to the batch_size" do
        described_class.perform_now(batch_size)

        expect(SendToQualifiedTeachersAPIJob).to have_been_enqueued.exactly(:once).with(participant_outcome_id: 1).on_queue("participant_outcomes")
        expect(SendToQualifiedTeachersAPIJob).not_to have_been_enqueued.with(participant_outcome_id: 2)
      end
    end
  end

  describe "#perform_later" do
    it "enqueues the job exactly once" do
      expect { described_class.perform_later }.to have_enqueued_job(described_class).exactly(:once).on_queue("participant_outcomes")
    end
  end
end