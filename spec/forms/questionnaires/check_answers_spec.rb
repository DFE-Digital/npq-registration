require "rails_helper"

RSpec.describe Questionnaires::CheckAnswers do
  subject(:instance) { described_class.new(wizard:) }

  let(:user_record_trn) { "7654321" }
  let(:user) { create(:user, trn: user_record_trn) }
  let(:load_provider) { LeadProvider.all.sample }
  let(:course) { create(:course) }
  let(:school) { create(:school) }
  let(:verified_trn) { rand(1_000_000..9_999_999).to_s }
  let(:store_trn) { "1234567" }
  let(:funding_eligiblity_status_code) { nil }
  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:wizard) { RegistrationWizard.new(current_step: :check_answers, store:, request:, current_user: user) }

  let(:store) do
    {
      lead_provider_id: load_provider.id,
      institution_identifier: "School-#{school.urn}",
      course_identifier: course.identifier,
      trn_verified: true,
      trn: store_trn,
      verified_trn:,
      confirmed_email: user&.email,
      funding_eligiblity_status_code:,
    }.stringify_keys
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it "goes to share_provider" do
      expect(subject).to be(:share_provider)
    end
  end

  describe "#show_previously_funded_alert?" do
    subject { instance.show_previously_funded_alert? }

    let(:funding_eligibility_calculator) { instance_double(FundingEligibility, funding_eligiblity_status_code:) }

    before { allow(FundingEligibility).to receive(:new_from_query_store).and_return(funding_eligibility_calculator) }

    context "when the pre-login funding eligibility status is funded" do
      before { store["pre_login_funding_eligiblity_status_code"] = :funded }

      context "when the current funding eligibility status is previously_funded" do
        let(:funding_eligiblity_status_code) { :previously_funded }

        it { is_expected.to be true }
      end

      context "when the current funding eligibility status is not previously_funded" do
        let(:funding_eligiblity_status_code) { :funded }

        it { is_expected.to be false }
      end
    end

    context "when the pre-login funding eligibility status is not funded" do
      let(:funding_eligiblity_status_code) { :ineligible_setting }

      before { store["pre_login_funding_eligiblity_status_code"] = :funded }

      it { is_expected.to be false }
    end
  end

  describe "#before_render" do
    subject { instance.before_render }

    let(:funding_eligiblity_status_code) { :funded }
    let(:funding_eligibility_calculator) { instance_double(FundingEligibility, funding_eligiblity_status_code: calculated_funding_eligiblity_status_code) }

    before { allow(FundingEligibility).to receive(:new_from_query_store).and_return(funding_eligibility_calculator) }

    context "when the user is not logged in" do
      let(:user) { nil }
      let(:calculated_funding_eligiblity_status_code) { :funded }

      it "sets pre_login_funding_eligiblity_status_code in the store" do
        expect { subject }.to change { wizard.store["pre_login_funding_eligiblity_status_code"] }.from(nil).to(:funded)
      end
    end

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
end
