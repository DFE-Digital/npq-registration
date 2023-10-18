require "rails_helper"

RSpec.describe Questionnaires::CheckAnswers do
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

  describe "#previous_step" do
    it "goes to share_provider" do
      expect(subject.previous_step).to be(:share_provider)
    end
  end
end
