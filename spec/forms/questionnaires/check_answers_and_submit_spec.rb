require "rails_helper"

RSpec.describe Questionnaires::CheckAnswersAndSubmit do
  subject(:instance) { described_class.new(wizard:) }

  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:session) { {} }
  let(:current_user) { build(:user) }
  let(:store) { {} }
  let(:funding_eligibility_calculator) { instance_double(FundingEligibility, funding_eligiblity_status_code: calculated_funding_eligiblity_status_code) }
  let(:calculated_funding_eligiblity_status_code) { nil }

  let(:wizard) do
    RegistrationWizard.new(
      current_step: :check_answers_and_submit,
      store:,
      request:,
      current_user:,
    )
  end

  before { allow(FundingEligibility).to receive(:new_from_query_store).and_return(funding_eligibility_calculator) }

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

  describe "#show_previously_funded_alert?" do
    subject { instance.show_previously_funded_alert? }

    context "when the pre-login funding eligibility status is funded" do
      before { store["pre_login_funding_eligiblity_status_code"] = :funded }

      context "when the current funding eligibility status is previously_funded" do
        let(:calculated_funding_eligiblity_status_code) { :previously_funded }

        it { is_expected.to be true }
      end

      context "when the current funding eligibility status is not previously_funded" do
        let(:calculated_funding_eligiblity_status_code) { :funded }

        it { is_expected.to be false }
      end
    end

    context "when the pre-login funding eligibility status is not funded" do
      before { store["pre_login_funding_eligiblity_status_code"] = :ineligible_setting }

      it { is_expected.to be false }
    end
  end

  describe "#before_render" do
    subject { instance.before_render }

    let(:store) { { funding_eligiblity_status_code: :funded }.stringify_keys }

    context "when the user is previously funded" do
      let(:calculated_funding_eligiblity_status_code) { :previously_funded }

      it "sets previously_funded in the store" do
        expect { subject }.to change { wizard.store["previously_funded"] }.from(nil).to(true)
      end

      it "updates the funding_eligibility_status_code in the store" do
        expect { subject }.to change { wizard.store["funding_eligiblity_status_code"] }.from(:funded).to(:previously_funded)
      end
    end

    context "when the user is not previously funded" do
      let(:calculated_funding_eligiblity_status_code) { :funded }

      it "does not set previously_funded in the store" do
        expect { subject }.not_to(change { wizard.store["previously_funded"] })
      end

      it "does not update the funding_eligibility_status_code in the store" do
        expect { subject }.not_to(change { wizard.store["show_previously_funded_alert"] })
      end
    end
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
