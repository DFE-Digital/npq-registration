require "rails_helper"

RSpec.describe Forms::ProviderCheck, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:chosen_provider).in_array(Forms::ProviderCheck::VALID_CHOSEN_PROVIDER_OPTIONS) }
  end

  describe "#previous_step" do
    let(:request) { nil }
    let(:store) { {} }
    let(:wizard) { RegistrationWizard.new(store: store, request: request, current_step: "provider_check") }

    before do
      subject.wizard = wizard
    end

    context "teacher" do
      let(:store) do
        {
          "teacher_status" => "yes",
        }
      end

      it "returns teacher_catchment" do
        expect(subject.previous_step).to eql(:teacher_catchment)
      end
    end

    context "non-teacher" do
      let(:store) do
        {
          "teacher_status" => "no",
        }
      end

      it "returns are_you_a_teacher" do
        expect(subject.previous_step).to eql(:are_you_a_teacher)
      end
    end
  end
end
