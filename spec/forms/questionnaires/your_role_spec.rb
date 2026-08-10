require "rails_helper"

RSpec.describe Questionnaires::YourRole, type: :model do
  subject(:instance) { described_class.new }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:your_employment) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to eq(:your_employer) }
  end
end
