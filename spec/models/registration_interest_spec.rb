require "rails_helper"

RSpec.describe RegistrationInterest do
  describe "validations" do
    subject { described_class.new(email: "email@example.com") }

    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_length_of(:email).is_at_most(128) }
    it { is_expected.to validate_presence_of(:course).with_message("is not included in the list") }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:course).with_values(
        "npq-senco": "npq-senco",
        other: "other",
      ).backed_by_column_of_type(:enum)
    }
  end
end
