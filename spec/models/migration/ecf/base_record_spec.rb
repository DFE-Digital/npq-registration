require "rails_helper"

class TestEcfModel < Migration::Ecf::BaseRecord
  self.table_name = "cohorts"
end

RSpec.describe Migration::Ecf::BaseRecord, type: :model do
  subject(:instance) { TestEcfModel.new }

  before { allow(Rails).to receive(:env) { environment.inquiry } }

  describe "#readonly?" do
    context "when in test environment" do
      let(:environment) { "test" }

      it { is_expected.not_to be_readonly }
    end

    context "when in non-test environment" do
      let(:environment) { "production" }

      it { is_expected.to be_readonly }
    end
  end
end
