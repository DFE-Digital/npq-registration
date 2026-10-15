require "rails_helper"

RSpec.describe Questionnaires::MathsUnderstandingOfApproach, :with_cohorts, type: :model do
  subject(:instance) { described_class.new }

  let(:course) { create(:course, :leading_primary_mathematics) }
  let(:lead_provider) { LeadProvider.for(course:).first }

  let(:store) do
    {
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id,
    }.stringify_keys
  end

  before do
    instance.wizard = RegistrationWizard.new(
      current_step: :maths_understanding_of_approach,
      store:,
      request: nil,
      current_user: create(:user),
    )
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to be :maths_eligibility_teaching_for_mastery }
  end
end
