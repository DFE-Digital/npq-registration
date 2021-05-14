require "rails_helper"

RSpec.describe RegistrationWizard do
  describe "#current_step" do
    subject { described_class.new(current_step: "share_provider") }

    it "returns current step" do
      expect(subject.current_step).to eql(:share_provider)
    end

    context "when invalid step" do
      subject { described_class.new(current_step: "i_do_not_exist") }

      it "raises an error" do
        expect {
          subject.current_step
        }.to raise_error(RegistrationWizard::InvalidStep)
      end
    end
  end
end
