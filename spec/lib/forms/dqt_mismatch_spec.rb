require "rails_helper"

RSpec.describe Forms::DqtMismatch do
  let(:request) { nil }
  let(:store) do
    { "teacher_catchment" => teacher_catchment,
      "works_in_school" => works_in_school,
      "works_in_childcare" => works_in_childcare }
  end
  let(:wizard) { RegistrationWizard.new(store:, request:, current_step: :dqt_mismatch) }

  subject(:step) { described_class.new.tap { |s| s.wizard = wizard } }

  describe "#next_step" do
    subject(:next_step) { step.next_step }

    context "when both in catchment and works in school" do
      let(:teacher_catchment) { "england" }
      let(:works_in_school) { "yes" }
      let(:works_in_childcare) { "no" }

      it { is_expected.to be :find_school }
    end

    context "when international teacher" do
      let(:teacher_catchment) { "other" }
      let(:works_in_school) { "yes" }
      let(:works_in_childcare) { "no" }

      it { is_expected.to be :choose_your_npq }
    end

    context "when inside catchment and working in childcare" do
      let(:teacher_catchment) { "england" }
      let(:works_in_school) { "no" }
      let(:works_in_childcare) { "yes" }

      it { is_expected.to be :work_in_nursery }
    end

    context "when not working in school or nursery" do
      let(:teacher_catchment) { "england" }
      let(:works_in_school) { "no" }
      let(:works_in_childcare) { "no" }

      it { is_expected.to be :choose_your_npq }
    end
  end
end
