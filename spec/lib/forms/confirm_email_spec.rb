require "rails_helper"

RSpec.describe Forms::ConfirmEmail, type: :model do
  let(:store) { {} }
  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:wizard) { RegistrationWizard.new(current_step: :confirm_email, store: store, session: session, request: request) }

  before do
    subject.wizard = wizard
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:confirmation_code) }
    it { is_expected.to validate_length_of(:confirmation_code).is_equal_to(6) }
  end

  describe "#after_save" do
    let(:store) do
      {
        "email" => "user@example.com",
      }
    end

    it "creates the user record" do
      expect {
        subject.after_save
      }.to change(User, :count).by(1)
    end

    context "when user record already exists" do
      before do
        User.create!(email: store["email"])
      end

      it "does not create another record" do
        expect {
          subject.after_save
        }.not_to change(User, :count)
      end
    end

    it "signs the user in" do
      subject.after_save
      user = User.last
      expect(subject.wizard.session["user_id"]).to eql(user.id)
    end
  end
end
