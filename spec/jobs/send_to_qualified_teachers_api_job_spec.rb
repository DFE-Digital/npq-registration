require "rails_helper"

RSpec.describe SendToQualifiedTeachersAPIJob, type: :job do
  describe "#perform" do
    let(:participant_outcome) { create_participant_outcome }
    let(:api_sender) { double }
    let!(:participant_outcome_id) { participant_outcome.id }

    subject(:job) { described_class.perform_now(participant_outcome_id:) }

    before do
      allow(QualifiedTeachersAPISender).to receive(:new).with(participant_outcome_id:).and_return(api_sender)
      allow(api_sender).to receive(:send_record).and_return(participant_outcome)
    end

    it "calls the correct service class" do
      job

      expect(api_sender).to have_received(:send_record)
    end
  end
end
