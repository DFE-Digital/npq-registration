require "rails_helper"

RSpec.describe Migration::Ecf::Finance::Schedule, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to have_many(:participant_profiles) }
  end

  describe "scopes" do
    describe "default_scope" do
      let!(:ecf_migration_schedule) { create(:ecf_migration_schedule) }

      before { create(:ecf_migration_schedule, type: "Finance::Schedule::ECF") }

      it "returns NPQ schedules only" do
        expect(described_class.all).to eq([ecf_migration_schedule])
      end
    end
  end
end
