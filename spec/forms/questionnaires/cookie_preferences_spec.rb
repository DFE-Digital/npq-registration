require "rails_helper"

RSpec.describe Questionnaires::CookiePreferences, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:consent).in_array(%w[accept reject]) }
  end
end
