require "rails_helper"

RSpec.describe Forms::RegistrationInterestNotification, type: :model do
  let(:existing_registration) { FactoryBot.create(:registration_interest) }
  before do
    subject { described_class.new }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:notification_option).in_array(Forms::RegistrationInterestNotification::VALID_NOTIFICATION_OPTIONS) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_length_of(:email).is_at_most(128) }

    describe "#can_register_interest" do
      context "trying to register the same email" do
        it "shows the form is invalid when trying to register again" do
          subject.email = existing_registration.email
          subject.valid?
          expect(subject.errors[:email]).to include("You have already registered to be notified")
        end
      end
    end

    describe "#selected_no?" do
      context "opting not to register" do
        it "does not provide an email error when selecting not to register interest" do
          subject.notification_option = "no"
          expect(subject.valid?).to be_truthy
        end
      end
    end
  end
end
