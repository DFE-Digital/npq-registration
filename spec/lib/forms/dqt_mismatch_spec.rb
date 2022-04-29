require "rails_helper"

RSpec.describe Forms::DqtMismatch do
  let(:request) { nil }
  let(:store) { { "teacher_catchment" => teacher_catchment, "works_in_school" => works_in_school, "works_in_childcare" => works_in_childcare } }
  let(:wizard) { RegistrationWizard.new(store: store, request: request, current_step: :dqt_mismatch) }

  subject(:step) { described_class.new.tap { |s| s.wizard = wizard } }

  describe "#next_step" do
    subject(:next_step) { step.next_step }

    context "when both in catchment and works in school" do
      let(:teacher_catchment) { "england" }
      let(:works_in_school) { "yes" }
      let(:works_in_childcare) { "no" }

      it { is_expected.to be :find_school }
    end

    context "when both in catchment and works in nursery" do
      let(:teacher_catchment) { "england" }
      let(:works_in_school) { "no" }
      let(:works_in_childcare) { "yes" }

      it { is_expected.to be :find_childcare_provider }
    end

    context "when international teacher" do
      let(:teacher_catchment) { "other" }
      let(:works_in_school) { "yes" }
      let(:works_in_childcare) { "no" }

      it { is_expected.to be :choose_your_npq }
    end

    context "when not working in school or nursery" do
      let(:teacher_catchment) { "england" }
      let(:works_in_school) { "no" }
      let(:works_in_childcare) { "no" }

      it { is_expected.to be :choose_your_npq }
    end
  end
end
