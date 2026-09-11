require "rails_helper"

RSpec.describe Questionnaires::IttProvider, type: :model do
  subject(:instance) { described_class.new(wizard:, itt_provider: approved_itt_provider.legal_name) }

  let(:wizard) { RegistrationWizard.new(current_step: :itt_provider, store:, request: nil, current_user: nil) }
  let(:store) { { course_identifier: course.identifier }.stringify_keys }
  let(:course) { Course.first }
  let(:approved_itt_provider) { create(:itt_provider) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:itt_provider) }
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:your_employment) }
  end
end
