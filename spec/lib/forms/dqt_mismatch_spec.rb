require "rails_helper"

RSpec.describe Forms::DqtMismatch do
  let(:request) { nil }
  let(:store) { { "teacher_catchment" => "england", "works_in_school" => "yes" } }
  let(:wizard) { RegistrationWizard.new(store: store, request: request, current_step: :dqt_mismatch) }

  subject(:step) { described_class.new.tap { |s| s.wizard = wizard } }

  describe "#next_step" do
    subject(:next_step) { step.next_step }

    context "when both in catchment and works in school" do
      it { is_expected.to be :find_school }
    end

    context "when international teacher" do
      let(:store) { super().merge("teacher_catchment" => "other") }

      it { is_expected.to be :choose_your_npq }
    end

    context "when not working in school" do
      let(:store) { super().merge("works_in_school" => "no") }

      it { is_expected.to be :choose_your_npq }
    end
  end
end
