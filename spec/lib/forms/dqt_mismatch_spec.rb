require "rails_helper"

RSpec.describe Forms::DqtMismatch do
  subject(:step) { described_class.new.tap { |s| s.wizard = wizard } }

  let(:request) { nil }
  let(:store) do
    {}
  end
  let(:wizard) { RegistrationWizard.new(store:, request:, current_step: :dqt_mismatch, current_user: create(:user)) }

  describe "#next_step" do
    subject(:next_step) { step.next_step }

    it { is_expected.to be :provider_check }
  end
end
