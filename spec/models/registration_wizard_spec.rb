require "rails_helper"

RSpec.describe RegistrationWizard do
  describe "#current_step" do
    let(:store) { {} }
    let(:session) { {} }
    let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }

    subject { described_class.new(current_step: "share_provider", store: store, request: request) }

    it "returns current step" do
      expect(subject.current_step).to eql(:share_provider)
    end

    context "when invalid step" do
      subject { described_class.new(current_step: "i_do_not_exist", store: store, request: request) }

      it "raises an error" do
        expect {
          subject.current_step
        }.to raise_error(RegistrationWizard::InvalidStep)
      end
    end
  end
end
