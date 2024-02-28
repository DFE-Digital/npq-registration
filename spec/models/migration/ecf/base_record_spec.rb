require "rails_helper"

class TestEcfModel < Migration::Ecf::BaseRecord
  self.table_name = "cohorts"
end

RSpec.describe Migration::Ecf::BaseRecord, type: :model do
  subject(:instance) { TestEcfModel.new }

  describe "#readonly?" do
    it { is_expected.to be_readonly }
  end
end
