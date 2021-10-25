require "rails_helper"

RSpec.describe Forms::DqtMismatch do
  let(:request) { nil }
  let(:store) { { "teacher_catchment" => "another" } }
  let(:wizard) { RegistrationWizard.new(store: store, request: request, current_step: :dqt_mismatch) }

  before do
    subject.wizard = wizard
  end

  describe "#next_step" do
    context "when international teacher" do
      it "return :choose_your_npq" do
        expect(subject.next_step).to eql(:choose_your_npq)
      end
    end
  end
end
