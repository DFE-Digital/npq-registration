require "rails_helper"

RSpec.describe Milestone, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:milestones_statements) }
    it { is_expected.to have_many(:statements).through(:milestones_statements) }
    it { is_expected.to belong_to(:schedule) }
  end
end
