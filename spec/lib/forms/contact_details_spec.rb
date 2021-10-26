require "rails_helper"

RSpec.describe Forms::ContactDetails, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_length_of(:email).is_at_most(128) }

    it "validates email addresses" do
      subject.email = "notvalid@example"
      subject.valid?
      expect(subject.errors[:email]).to be_present

      subject.email = "valid@example.com"
      subject.valid?
      expect(subject.errors[:email]).not_to be_present
    end
  end

  describe "#previous_step" do
    it "return name_changes" do
      expect(subject.previous_step).to eql(:teacher_reference_number)
    end
  end

  describe "#after_save" do
    let(:store) { {} }
    let(:session) { {} }
    let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
    let(:wizard) { RegistrationWizard.new(current_step: :contact_details, store: store, request: request) }

    subject { described_class.new(email: " User@example.com ", wizard: wizard) }

    it "sends email to downcased version" do
      expect {
        subject.after_save
      }.to change(ActionMailer::Base.deliveries, :count).by(1)

      email = ActionMailer::Base.deliveries.last

      expect(email.to).to eql(["user@example.com"])
    end

    it "sets flash message" do
      subject.after_save
      expect(subject.wizard.request.flash[:success]).to eql("We’ve emailed a confirmation code to user@example.com")
    end

    context "when whitelisted domain and in sandbox" do
      before do
        allow(ENV).to receive(:[]).with("SERVICE_ENV").and_return("sandbox")
      end

      it "displays code in flash message" do
        subject.after_save
        expect(subject.wizard.request.flash[:success]).to match(/Your code is \d{6}/)
      end
    end
  end
end
