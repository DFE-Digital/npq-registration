require "rails_helper"

RSpec.describe Questionnaires::CheckAnswersAndSubmit do
  subject(:instance) { described_class.new(wizard:) }

  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:session) { {} }

  let(:wizard) do
    RegistrationWizard.new(
      current_step: :check_answers_and_submit,
      store: {},
      request:,
      current_user: nil,
    )
  end

  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    it { is_expected.to be(:share_provider) }
  end

  describe "#next_step" do
    subject { described_class.new(wizard:).next_step }

    it { is_expected.to be_nil }
  end

  describe "#last_step?" do
    subject { described_class.new(wizard:).last_step? }

    it { is_expected.to be true }
  end

  describe "#after_save" do
    subject(:after_save) { described_class.new(wizard:).after_save }

    let(:handle_submission_for_store) { instance_double(HandleSubmissionForStore, call: true) }

    before do
      allow(HandleSubmissionForStore).to receive(:new).with(store: wizard.store).and_return(handle_submission_for_store)
      allow(EmailTemplate).to receive(:call).with(data: wizard.store).and_return(:some_email_template)
    end

    it "sets the email template and submitted flag in the wizard store" do
      expect { subject }.to change { wizard.store["email_template"] }.from(nil).to(:some_email_template)
    end

    it "sets the submitted flag to true in the wizard store" do
      expect { subject }.to change { wizard.store["submitted"] }.from(nil).to(true)
    end

    it "sets the clear_tra_login flag to true in the wizard session" do
      expect { subject }.to change { wizard.session["clear_tra_login"] }.from(nil).to(true)
    end

    it "calls HandleSubmissionForStore" do
      expect(handle_submission_for_store).to receive(:call)

      subject
    end
  end
end
