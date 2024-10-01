require "rails_helper"

RSpec.describe Migration::ParityCheckComparison, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_inclusion_of(:method).in_array(%w[get post put]) }
    it { is_expected.to validate_inclusion_of(:ecf_status).in_range(100..599) }
    it { is_expected.to validate_inclusion_of(:npq_status).in_range(100..599) }
    it { is_expected.to validate_presence_of(:ecf_response) }
    it { is_expected.to validate_presence_of(:npq_response) }
  end
end
