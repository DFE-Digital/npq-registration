require "rails_helper"

RSpec.describe Questionnaires::MathsCannotRegister, type: :model do
  subject(:instance) { described_class.new }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:maths_understanding_of_approach) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to be_nil }
  end
end
