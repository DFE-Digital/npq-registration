require "rails_helper"

RSpec.describe Forms::CheckAnswers do
  let(:user_record_trn) { "7654321" }
  let(:user) { create(:user, trn: user_record_trn) }
  let(:load_provider) { LeadProvider.all.sample }
  let(:course) { Course.all.sample }
  let(:school) { create(:school) }
  let(:verified_trn) { rand(1_000_000..9_999_999).to_s }
  let(:store_trn) { "1234567" }
  let(:store) do
    {
      lead_provider_id: load_provider.id,
      institution_identifier: "School-#{school.urn}",
      course_identifier: course.identifier,
      trn_verified: true,
      trn: store_trn,
      verified_trn:,
      confirmed_email: user.email,
    }.stringify_keys
  end
  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:wizard) { RegistrationWizard.new(current_step: :check_answers, store:, request:, current_user: user) }

  describe "#after_save" do
    before do
      mock_previous_funding_api_request(
        course_identifier: course.identifier,
        trn: "1234567",
        response: ecf_funding_lookup_response(previously_funded: false),
      )
    end

    context "when TRA feature flag is enabled" do
      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?).with(Services::Feature::GAI_INTEGRATION_KEY, anything).and_return(true)
      end

      context "when verified_trn and entered trn differ" do
        it "uses trn from TRN record" do
          subject.wizard = wizard
          subject.after_save

          user.reload

          expect(user.trn).to eql(user_record_trn)
        end
      end

      context "when verified_trn and entered trn are the same" do
        let(:verified_trn) { store_trn }

        it "uses trn from TRN record" do
          subject.wizard = wizard
          subject.after_save

          user.reload

          expect(user.trn).to eql(user_record_trn)
        end
      end
    end

    context "when TRA feature flag is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).and_call_original
        allow(Flipper).to receive(:enabled?).with(Services::Feature::GAI_INTEGRATION_KEY, anything).and_return(false)
      end

      context "when verified_trn and entered trn differ" do
        it "uses verified_trn" do
          subject.wizard = wizard
          subject.after_save

          user.reload

          expect(user.trn).to eql(verified_trn)
        end
      end

      context "when trn_auto_verified is nil" do
        before do
          store["trn_auto_verified"] = nil
        end

        it "persists as false" do
          subject.wizard = wizard
          subject.after_save

          user.reload

          expect(user.trn_auto_verified).to be(false)
        end
      end
    end
  end

  describe "#previous_step" do
    it "goes to share_provider" do
      expect(subject.previous_step).to be(:share_provider)
    end
  end
end
