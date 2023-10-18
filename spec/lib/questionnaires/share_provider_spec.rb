require "rails_helper"

RSpec.describe Questionnaires::ShareProvider, type: :model do
  subject(:model) { described_class.new }

  describe "validations" do
    it { is_expected.to validate_acceptance_of(:can_share_choices) }
  end

  describe "#next_step" do
    subject(:next_step) { model.next_step }

    it { is_expected.to be :check_answers }
  end

  describe "#previous_step" do
    subject(:previous_step) { model.previous_step }

    it { is_expected.to be :choose_your_provider }
  end
end
