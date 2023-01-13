require "rails_helper"

RSpec.describe IttProvider, type: :model do
  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:legal_name) }
    it { is_expected.to validate_presence_of(:legal_name) }
    it { is_expected.to validate_presence_of(:operating_name) }
  end
end
