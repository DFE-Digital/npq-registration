require "rails_helper"

RSpec.describe Questionnaires::MathsEligibilityTeachingForMastery, :with_cohorts, type: :model do
  let(:instance) { described_class.new }
  let(:course) { create(:course, :leading_primary_mathematics) }
  let(:lead_provider) { LeadProvider.for(course:).first }

  let(:store) do
    {
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id,
      current_user: build_stubbed(:user),
    }.stringify_keys
  end

  before do
    instance.wizard = RegistrationWizard.new(
      current_step: :maths_eligibility_teaching_for_mastery,
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
