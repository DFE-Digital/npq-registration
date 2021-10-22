require "rails_helper"

RSpec.describe Forms::ProviderCheck, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:chosen_provider).in_array(Forms::ProviderCheck::VALID_CHOSEN_PROVIDER_OPTIONS) }
  end

  describe "#previous_step" do
    it "returns teacher_catchment" do
      expect(subject.previous_step).to eql(:teacher_catchment)
    end
  end
end
