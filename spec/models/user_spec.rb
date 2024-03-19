require "rails_helper"

RSpec.describe User do
  describe "relationships" do
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:ecf_sync_request_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:full_name) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }

    it { is_expected.to validate_uniqueness_of(:uid).allow_blank }

    it "does not allow a uid to change once set" do
      user = create(:user, uid: "123")
      user.uid = "456"

      expect(user).to be_invalid
      expect(user.errors[:uid]).to be_present
    end
  end

  describe "methods" do
    it { expect(User.new).to be_actual_user }
    it { expect(User.new).not_to be_null_user }
  end
end
