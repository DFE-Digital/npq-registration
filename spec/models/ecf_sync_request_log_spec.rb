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

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:status).with_values(
        success: "success",
        failed: "failed",
      ).backed_by_column_of_type(:string).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:sync_type).with_values(
        user_lookup: "user_lookup",
        user_update: "user_update",
        user_creation: "user_creation",
        get_an_identity_id_sync: "get_an_identity_id_sync",
        application_creation: "application_creation",
      ).backed_by_column_of_type(:string).with_suffix
    }
  end
end
