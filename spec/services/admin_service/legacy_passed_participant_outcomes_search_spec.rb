require "rails_helper"

RSpec.describe AdminService::LegacyPassedParticipantOutcomesSearch do
  subject { described_class.new(trn:) }

  let(:legacy_passed_participant_outcome) { create(:legacy_passed_participant_outcome) }
  let(:trn) { legacy_passed_participant_outcome.trn }

  describe "#call" do
    subject { described_class.new(trn:).call }

    it { is_expected.to contain_exactly(legacy_passed_participant_outcome) }
  end
end
