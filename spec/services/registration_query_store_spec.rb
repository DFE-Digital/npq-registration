# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegistrationQueryStore do
  let(:store) do
    {
      course_start_cohort:,
      check_funding:,
      declared_previous_funding:,
      pre_login_funding_eligiblity_status_code:,
    }.stringify_keys
  end

  let(:course_start_cohort) { nil }
  let(:check_funding) { nil }
  let(:declared_previous_funding) { nil }
  let(:pre_login_funding_eligiblity_status_code) { nil }

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

  describe "#proceed_without_checking_funding?" do
    subject { described_class.new(store:).proceed_without_checking_funding? }

    context "when check_funding is 'yes'" do
      let(:check_funding) { "yes" }

      it { is_expected.to be false }
    end

    context "when check_funding is 'no'" do
      let(:check_funding) { "no" }

      it { is_expected.to be true }
    end

    context "when check_funding is not present in the store" do
      let(:store) { {} }

      it { is_expected.to be false }
    end
  end

  describe "#declared_previous_funding?" do
    subject { described_class.new(store:).declared_previous_funding? }

    context "when declared_previous_funding is 'yes'" do
      let(:declared_previous_funding) { "yes" }

      it { is_expected.to be true }
    end

    context "when declared_previous_funding is 'no'" do
      let(:declared_previous_funding) { "no" }

      it { is_expected.to be false }
    end
  end

  describe "#has_answers?" do
    subject { described_class.new(store:).has_answers? }

    context "when the store is empty" do
      let(:store) { {} }

      it { is_expected.to be false }
    end

    context "when the store only has user id" do
      let(:store) { { current_user_id: 123 }.stringify_keys }

      it { is_expected.to be false }
    end

    context "when the store has at least one answer" do
      let(:store) { { course_start_cohort: "2026b" }.stringify_keys }

      it { is_expected.to be true }
    end
  end

  describe "#new_headteacher?" do
    subject { described_class.new(store:).new_headteacher? }

    context "when ehco_new_headteacher is 'yes'" do
      let(:store) { { ehco_new_headteacher: "yes" }.stringify_keys }

      it { is_expected.to be true }
    end

    context "when ehco_new_headteacher is 'no'" do
      let(:store) { { ehco_new_headteacher: "no" }.stringify_keys }

      it { is_expected.to be false }
    end
  end

  describe "#clear_optional_work_setting_answers!" do
    subject { described_class.new(store:).clear_optional_work_setting_answers! }

    let(:answers_before_work_setting) do
      {
        check_funding: "yes",
        course_start_cohort: "2026b",
        declared_previous_funding: "no",
        npq_course_identifier: "npq-headship",
        teacher_catchment: "england",
      }.stringify_keys
    end

    let(:optional_work_setting_answers) do
      {
        childcare_identifier: "123",
        childcare_name: "ABC Nursery",
        employer_name: "XYZ School",
        employment_role: "Teacher",
        employment_type: "Full-time",
        has_ofsted_urn: "yes",
        institution_identifier: "456",
        institution_name: "DEF School",
        kind_of_nursery: "Private",
        private_childcare_identifier: "789",
        private_childcare_name: "GHI Nursery",
        referred_by_return_to_teaching_adviser: "no",
      }.stringify_keys
    end

    let(:store) do
      answers_before_work_setting.merge(optional_work_setting_answers)
    end

    it "removes all optional work setting answers from the store" do
      subject
      expect(store).to eq(answers_before_work_setting)
    end
  end

  describe "#user_eligible_for_funding_before_login?" do
    subject { described_class.new(store:).user_eligible_for_funding_before_login? }

    context "when pre_login_funding_eligiblity_status_code is 'funded'" do
      let(:pre_login_funding_eligiblity_status_code) { FundingEligibility::FUNDED_ELIGIBILITY_RESULT }

      it { is_expected.to be true }
    end

    context "when pre_login_funding_eligiblity_status_code is not 'funded'" do
      let(:pre_login_funding_eligiblity_status_code) { FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE }

      it { is_expected.to be false }
    end

    context "when pre_login_funding_eligiblity_status_code is nil" do
      let(:pre_login_funding_eligiblity_status_code) { nil }

      it { is_expected.to be false }
    end
  end
end
