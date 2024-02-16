require "rails_helper"

RSpec.describe EcfSyncRequestLog, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:syncable) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:syncable) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:sync_type) }
  end
end
