require "rails_helper"

RSpec.describe Forms::ContactDetails, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }

    it "validates email addresses" do
      subject.email = "notvalid@example"
      subject.valid?
      expect(subject.errors[:email]).to be_present

      subject.email = "valid@example.com"
      subject.valid?
      expect(subject.errors[:email]).not_to be_present
    end
  end
end
