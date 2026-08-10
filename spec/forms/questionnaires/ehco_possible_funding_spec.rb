require "rails_helper"

RSpec.describe Questionnaires::EhcoPossibleFunding, type: :model do
  subject(:instance) { described_class.new }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:ehco_new_headteacher) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to eq(:choose_your_provider) }
  end
end
