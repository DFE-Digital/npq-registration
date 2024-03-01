require "rails_helper"

RSpec.describe Migration::Ecf::Finance::Statement, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:cpd_lead_provider) }
    it { is_expected.to have_one(:npq_lead_provider).through(:cpd_lead_provider) }
  end

  describe "scopes" do
    describe "default_scope" do
      let!(:ecf_migration_npq_statement) { create(:ecf_migration_statement) }

      before { create(:ecf_migration_statement, type: "Finance::Statement::ECF") }

      it "returns NPQ statements only" do
        expect(described_class.all).to eq([ecf_migration_npq_statement])
      end
    end
  end
end
