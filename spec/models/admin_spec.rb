require "rails_helper"

RSpec.describe Admin, type: :model do
  describe "validation" do
    describe "full_name" do
      it { is_expected.to validate_presence_of(:full_name).with_message("Enter a full name") }
      it { is_expected.to validate_length_of(:full_name).is_at_most(64).with_message("Full name must be shorter than 64 characters") }
    end

    describe "email" do
      it { is_expected.to validate_presence_of(:email).with_message("Enter an email address") }
      it { is_expected.to validate_length_of(:email).is_at_most(64).with_message("Email must be shorter than 64 characters") }
    end
  end

  describe "defaults" do
    specify "super_admin defaults to false" do
      expect(Admin.new.super_admin?).to be false
    end
  end
end
