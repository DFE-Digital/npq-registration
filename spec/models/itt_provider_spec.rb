require "rails_helper"

RSpec.describe IttProvider, type: :model do
  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:legal_name) }
    it { is_expected.to validate_presence_of(:legal_name) }
    it { is_expected.to validate_presence_of(:operating_name) }
  end

  describe "default_scope" do
    subject { described_class.all }

    let!(:enabled_provider) { create(:itt_provider) }
    let!(:disabled_provider) { create(:itt_provider, :disabled) }

    it { is_expected.to include(enabled_provider) }
    it { is_expected.not_to include(disabled_provider) }
  end
end
