require "rails_helper"

RSpec.describe Questionnaires::EhcoNewHeadteacher, type: :model do
  let(:instance) { described_class.new }
  let(:course) { create(:course, :senco) }
  let(:lead_provider) { create(:lead_provider) }
  let(:teacher_catchment) { nil }

  let(:store) do
    {
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id,
      current_user: build_stubbed(:user),
      teacher_catchment:,
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

  it { is_expected.to validate_inclusion_of(:ehco_new_headteacher).in_array(Questionnaires::EhcoNewHeadteacher::VALID_EHCO_NEW_HEADTEACHER_OPTIONS) }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to be :npqh_status }
  end
end
