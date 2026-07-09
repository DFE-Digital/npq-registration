# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegistrationQueryStore do
  let(:store) do
    {
      course_start_cohort:,
      check_funding:,
    }.stringify_keys
  end

  let(:check_funding) { nil }

  describe "#cohort_funded?" do
    subject { described_class.new(store:).cohort_funded? }

    context "when the course start cohort is not funded" do
      let(:cohort) { create(:cohort, :unfunded) }
      let(:course_start_cohort) { cohort.identifier }

      it { is_expected.to be false }
    end

    context "when the course start cohort is funded" do
      let(:cohort) { create(:cohort, :capped) }
      let(:course_start_cohort) { cohort.identifier }

      it { is_expected.to be true }
    end

    context "when the course start cohort is nil" do
      let(:course_start_cohort) { nil }

      it { is_expected.to be true }
    end
  end

  describe "#check_funding?" do
    subject { described_class.new(store:).check_funding? }

    let(:course_start_cohort) { "2026b" }

    context "when check_funding is 'yes'" do
      let(:check_funding) { "yes" }

      it { is_expected.to be true }
    end

    context "when check_funding is nil" do
      let(:check_funding) { nil }

      it { is_expected.to be false }
    end
  end
end
