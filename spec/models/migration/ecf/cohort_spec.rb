require "rails_helper"

RSpec.describe Migration::Ecf::Cohort, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:statements).class_name("Finance::Statement") }
  end
end
