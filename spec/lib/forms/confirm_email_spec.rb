require "rails_helper"

RSpec.describe Forms::ConfirmEmail, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:confirmation_code) }
    it { is_expected.to validate_length_of(:confirmation_code).is_equal_to(6) }
  end
end
