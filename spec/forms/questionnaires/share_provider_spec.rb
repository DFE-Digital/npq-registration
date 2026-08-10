require "rails_helper"

RSpec.describe Questionnaires::ShareProvider, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :share_provider, store: {}, request: nil, current_user:) }
  let(:current_user) { nil }

  describe "validations" do
    it { is_expected.to validate_acceptance_of(:can_share_choices) }
  end

  describe "#previous_step" do
    subject(:previous_step) { instance.previous_step }

    it { is_expected.to be :choose_your_provider }
  end

  describe "#next_step" do
    subject(:next_step) { instance.next_step }

    context "when the user is not logged in" do
      it { is_expected.to be :check_answers }
    end

    context "when the user is logged in with GAI" do
      let(:current_user) { build(:user, :with_get_an_identity_id) }

      it { is_expected.to be :check_answers }
    end

    context "when the user is logged in with Teacher Auth" do
      let(:current_user) { build(:user, :with_teacher_auth) }

      it { is_expected.to be :check_answers_and_submit }
    end
  end
end
