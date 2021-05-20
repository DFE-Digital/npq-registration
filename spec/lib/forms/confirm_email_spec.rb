require "rails_helper"

RSpec.describe Forms::ConfirmEmail, type: :model do
  let(:store) { {} }
  let(:wizard) { RegistrationWizard.new(current_step: :confirm_email, store: store) }

  before do
    subject.wizard = wizard
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:confirmation_code) }
    it { is_expected.to validate_length_of(:confirmation_code).is_equal_to(6) }
  end
end
