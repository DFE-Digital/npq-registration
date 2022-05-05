require "rails_helper"

RSpec.describe Forms::DqtMismatch do
  let(:request) { nil }
  let(:store) { { "teacher_catchment" => teacher_catchment, "works_in_school" => works_in_school } }
  let(:wizard) { RegistrationWizard.new(store: store, request: request, current_step: :dqt_mismatch) }

  subject(:step) { described_class.new.tap { |s| s.wizard = wizard } }

  describe "#next_step" do
    subject(:next_step) { step.next_step }

    context "when both in catchment and works in school" do
      let(:teacher_catchment) { "england" }
      let(:works_in_school) { "yes" }

      it { is_expected.to be :find_school }
    end

    context "when international teacher" do
      let(:teacher_catchment) { "other" }
      let(:works_in_school) { "yes" }

      it { is_expected.to be :work_in_childcare }
    end

    context "when not working in school or nursery" do
      let(:teacher_catchment) { "england" }
      let(:works_in_school) { "no" }

      it { is_expected.to be :work_in_childcare }
    end
  end
end
