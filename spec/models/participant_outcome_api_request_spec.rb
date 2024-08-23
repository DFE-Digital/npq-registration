require "rails_helper"

RSpec.describe ParticipantOutcomeAPIRequest, type: :model do
  subject(:participant_outcome_api_request) { create(:participant_outcome_api_request) }

  describe "associations" do
    it { is_expected.to belong_to(:participant_outcome) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:ecf_id) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
  end
end
