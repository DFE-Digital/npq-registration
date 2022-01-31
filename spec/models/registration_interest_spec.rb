require "rails_helper"

RSpec.describe RegistrationInterest do
  describe "validations" do
    subject { RegistrationInterest.new(email: "email@example.com") }

    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_length_of(:email).is_at_most(128) }
  end
end
