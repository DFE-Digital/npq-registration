require "rails_helper"

RSpec.describe Questionnaires::ContinueToLogin, type: :model do
  subject(:instance) { described_class.new }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to be(:check_answers) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to be(:check_answers_and_submit) }
  end
end
