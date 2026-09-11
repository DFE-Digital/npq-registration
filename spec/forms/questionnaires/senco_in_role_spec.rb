require "rails_helper"

RSpec.describe Questionnaires::SencoInRole, type: :model do
  let(:instance) { described_class.new }
  let(:course) { create(:course, :senco) }
  let(:lead_provider) { create(:lead_provider) }

  let(:store) do
    {
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id,
      current_user: build_stubbed(:user),
    }.stringify_keys
  end

  before do
    create(:course_cohort, :with_provider, course:, cohort: create(:cohort), lead_provider:)
    instance.wizard = RegistrationWizard.new(
      current_step: :senco_in_role,
      store:,
      request: nil,
      current_user: nil,
    )
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to be :work_setting }
  end
end
