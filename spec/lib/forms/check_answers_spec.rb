require "rails_helper"

RSpec.describe Forms::CheckAnswers do
  let(:user) { create(:user) }
  let(:load_provider) { LeadProvider.all.sample }
  let(:course) { Course.all.sample }
  let(:school) { create(:school) }
  let(:verified_trn) { rand(1_000_000..9_999_999).to_s }
  let(:store) do
    {
      lead_provider_id: load_provider.id,
      institution_identifier: "School-#{school.urn}",
      course_id: course.id,
      trn_verified: true,
      trn: "1234567",
      verified_trn: verified_trn,
      confirmed_email: user.email,
    }.stringify_keys
  end
  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:wizard) { RegistrationWizard.new(current_step: :check_answers, store: store, request: request) }

  describe "#after_save" do
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

        expect(user.trn_auto_verified).to eql(false)
      end
    end
  end

  describe "#previous_step" do
    it "goes to share_provider" do
      expect(subject.previous_step).to eql(:share_provider)
    end
  end
end
