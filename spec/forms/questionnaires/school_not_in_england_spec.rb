require "rails_helper"

RSpec.describe Questionnaires::SchoolNotInEngland, type: :model do
  subject(:instance) { described_class.new }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:work_setting) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to be_nil }
  end
end
