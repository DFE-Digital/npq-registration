require "rails_helper"

RSpec.describe Migration::Ecf::CpdLeadProvider, type: :model do
  describe "associations" do
    it { is_expected.to have_one(:npq_lead_provider) }
    it { is_expected.to have_many(:statements).class_name("Finance::Statement") }
  end
end
