require "rails_helper"

RSpec.describe Forms::ChooseYourProvider, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }
  end
end
