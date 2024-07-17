# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ehco::TargetedDeliveryFundingEligibilityUpdater do
  subject { described_class.run(logger:) }

  let(:ehco_course) { Course.ehco }
  let(:logger) { object_double("logger", info: nil) }

  let(:applicable_application_hash) do
    {
      course: ehco_course,
      targeted_delivery_funding_eligibility: true,
    }
  end

  let!(:application_with_targeted_funding_set)     { create(:application, applicable_application_hash) }
  let!(:application_with_targeted_funding_set_two) { create(:application, applicable_application_hash) }
  let!(:application_before_cutoff)                 { create(:application, applicable_application_hash.merge(created_at: Feature::REGISTRATION_OPEN_DATE - 1.day)) }
  let!(:application_wrong_course)                  { create(:application, applicable_application_hash.merge(course: Course.npqeyl)) }
  let!(:application_not_marked_for_funding)        { create(:application, applicable_application_hash.merge(targeted_delivery_funding_eligibility: false)) }

  it "updates the targeted_delivery_funding_eligibility flag for applicable records" do
    expect { subject }.to change {
      [
        application_with_targeted_funding_set,
        application_with_targeted_funding_set_two,
      ].each(&:reload).map(&:targeted_delivery_funding_eligibility)
    }.from([true, true]).to([false, false])
  end

  it "does not update the targeted_delivery_funding_eligibility flag for inapplicable records" do
    expect { subject }.not_to(change do
      [
        application_before_cutoff,
        application_wrong_course,
        application_not_marked_for_funding,
      ].each(&:reload).map(&:targeted_delivery_funding_eligibility)
    end)
  end
end
