require "rails_helper"

RSpec.describe Migration::Ecf::Finance::Milestone, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:schedule) }
  end
end
