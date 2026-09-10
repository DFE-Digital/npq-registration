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

  describe "#next_step" do
    subject { instance.next_step }

    it_behaves_like "showing the eligibility step"
  end
end
