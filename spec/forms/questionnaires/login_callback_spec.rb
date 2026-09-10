require "rails_helper"

RSpec.describe Questionnaires::LoginCallback do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :login_callback, store: {}, request: nil, current_user: nil) }

  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    it { is_expected.to be(:continue_to_login) }
  end

  describe "#next_step" do
    subject { described_class.new(wizard:).next_step }

    it { is_expected.to be(:check_answers_and_submit) }
  end
end
