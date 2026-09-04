require "rails_helper"

RSpec.describe Questionnaires::CheckAnswers do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :check_answers, store:, request: nil, current_user: nil) }
  let(:store) { {} }

  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    it { is_expected.to be(:share_provider) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to be(:continue_to_login) }
  end

  describe "#before_render" do
    subject { instance.before_render }

    let(:store) { { funding_eligiblity_status_code: :funded }.stringify_keys }

    it "sets pre_login_funding_eligiblity_status_code in the store" do
      expect { subject }.to change { wizard.store["pre_login_funding_eligiblity_status_code"] }.from(nil).to(:funded)
    end
  end
end
