require "rails_helper"

RSpec.describe Questionnaires::NpqhStatus, type: :model do
  it { is_expected.to validate_inclusion_of(:npqh_status).in_array(Questionnaires::NpqhStatus::VALID_NPQH_STATUS_OPTIONS) }

  describe "#previous_step" do
    it do
      expect(subject.previous_step).to be(:choose_your_npq)
    end
  end
end
