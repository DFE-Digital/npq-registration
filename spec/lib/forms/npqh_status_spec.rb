require "rails_helper"

RSpec.describe Forms::NpqhStatus, type: :model do
  it { is_expected.to validate_inclusion_of(:npqh_status).in_array(Forms::NpqhStatus::VALID_NPQH_STATUS_OPTIONS) }

  describe "#previous_step" do
    it do
      expect(subject.previous_step).to eql(:about_ehco)
    end
  end
end
