require "rails_helper"

RSpec.describe Forms::ChooseYourNpq, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:npq) }
  end
end
