require "rails_helper"

RSpec.describe Admin::ApplicationsController, type: :controller do
  describe "PATCH #update_approval_status" do
    it "updates the approval status and redirects" do
      application = FactoryBot.create(:application)
      patch :update_approval_status, params: { id: application.id }
      expect(application.reload.lead_provider_approval_status).not_to eq(application.get_approval_status)
    end
  end

  describe "PATCH #update_participant_outcome" do
    it "updates the participant outcome and redirects" do
      application = FactoryBot.create(:application)
      patch :update_participant_outcome, params: { id: application.id }
      expect(application.reload.participant_outcome_state).not_to eq(application.get_participant_outcome_state)
    end
  end
end
