require "rails_helper"

RSpec.describe Migration::Ecf::NpqContract, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:npq_lead_provider) }
    it { is_expected.to belong_to(:npq_course) }
    it { is_expected.to belong_to(:cohort) }
  end
end
