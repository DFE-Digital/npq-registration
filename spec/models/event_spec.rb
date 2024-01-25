require "rails_helper"

RSpec.describe Event, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:user).required(false) }
    it { is_expected.to belong_to(:application).required(false) }
    it { is_expected.to belong_to(:course).required(false) }
    it { is_expected.to belong_to(:lead_provider).required(false) }
    it { is_expected.to belong_to(:school).required(false) }
    it { is_expected.to belong_to(:statement).required(false) }
    it { is_expected.to belong_to(:statement_item).required(false) }
    it { is_expected.to belong_to(:declaration).required(false) }
  end
end
