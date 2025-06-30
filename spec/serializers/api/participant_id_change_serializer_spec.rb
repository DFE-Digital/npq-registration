require "rails_helper"

RSpec.describe API::ParticipantIdChangeSerializer do
  subject { described_class.render_as_hash(participant_id_change) }

  let(:participant_id_change) { create(:participant_id_change, created_at: Time.zone.parse("2024-01-01T12:00:00Z")) }

  it "serializes the correct fields" do
    expect(subject).to eq(
      from_participant_id: participant_id_change.from_participant_id,
      to_participant_id: participant_id_change.to_participant_id,
      changed_at: "2024-01-01T12:00:00Z",
    )
  end
end
