require "rails_helper"

RSpec.describe Admin, type: :model do
  describe "validation" do
    describe "full_name" do
      it { is_expected.to validate_presence_of(:full_name) }
      it { is_expected.to validate_length_of(:full_name).is_at_most(64) }
    end

    describe "email" do
      it { is_expected.to validate_presence_of(:email) }
      it { is_expected.to validate_length_of(:email).is_at_most(64) }
    end
  end

  describe "defaults" do
    specify "super_admin defaults to false" do
      expect(Admin.new.super_admin?).to be false
    end
  end
end
