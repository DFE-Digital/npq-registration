require "rails_helper"

RSpec.describe Questionnaires::ReferredByReturnToTeachingAdviser, type: :model do
  subject(:instance) { described_class.new(referred_by_return_to_teaching_adviser:) }

  let(:referred_by_return_to_teaching_adviser) { nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:referred_by_return_to_teaching_adviser) }
    it { is_expected.to validate_inclusion_of(:referred_by_return_to_teaching_adviser).in_array(%w[yes no]) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it_behaves_like "showing the eligibility step"
  end
end
