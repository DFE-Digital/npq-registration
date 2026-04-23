require "rails_helper"

RSpec.describe Questionnaires::CourseStartDate, type: :model do
  subject(:instance) { described_class.new(wizard:, course_start_cohort:) }

  let(:current_step) { :course_start_date }
  let(:user) { create(:user) }
  let(:wizard) { RegistrationWizard.new(current_step:, store: {}, request: nil, current_user: user) }
  let(:course_start_cohort) { "" }

  describe "validations" do
    it { is_expected.to validate_presence_of(:course_start_cohort) }
    it { is_expected.to validate_inclusion_of(:course_start_cohort).in_array(described_class::OPTIONS.keys) }

    context "when the course_start_cohort does not correspond to an existing cohort" do
      it { is_expected.to have_error(:course_start_cohort, :invalid) }
    end

    context "when the course_start_cohort corresponds to an existing cohort" do
      before do
        instance.course_start_cohort = described_class::OPTIONS.keys.first
        create(:cohort, start_year: 2026)
      end

      it { is_expected.to be_valid }
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to eq(:provider_check) }
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:start) }
  end
end
