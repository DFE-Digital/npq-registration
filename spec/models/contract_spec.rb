require "rails_helper"

RSpec.describe Contract, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:statement) }
    it { is_expected.to belong_to(:course) }
  end
end
