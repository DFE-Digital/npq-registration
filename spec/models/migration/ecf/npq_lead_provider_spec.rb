require "rails_helper"

RSpec.describe Migration::Ecf::NpqLeadProvider, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cpd_lead_provider).optional }
    it { is_expected.to have_many(:statements).through(:cpd_lead_provider).class_name("Finance::Statement") }
  end
end
