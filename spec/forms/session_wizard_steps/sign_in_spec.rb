require "rails_helper"

RSpec.describe SessionWizardSteps::SignIn, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end
end
