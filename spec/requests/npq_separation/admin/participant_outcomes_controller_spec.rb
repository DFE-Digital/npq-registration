require "rails_helper"

RSpec.describe NpqSeparation::Admin::ParticipantOutcomesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/participant_outcomes/:id/resend" do
    subject :do_request do
      sign_in_as_admin
      get resend_npq_separation_admin_participant_outcome_path(participant_outcome)
      response
    end

    let :participant_outcome do
      create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api)
    end

    it "redirects back to the applications page" do
      expect(do_request).to redirect_to \
        npq_separation_admin_application_path(participant_outcome.application_id)
    end

    it "confirms requeuing delivery of the api request" do
      do_request

      expect(flash[:success]).to match(/rescheduled/i)
    end

    it "requeues delivery of the api request" do
      expect {
        do_request
        participant_outcome.reload
      }.to change(participant_outcome, :sent_to_qualified_teachers_api_at?)
    end

    context "with already successfully sent participant outcome" do
      let :participant_outcome do
        create(:participant_outcome, :successfully_sent_to_qualified_teachers_api)
      end

      it "redirects back to the applications page" do
        expect(do_request).to redirect_to \
          npq_separation_admin_application_path(participant_outcome.application_id)
      end

      it "refuses requeuing delivery of the api request" do
        do_request

        expect(flash[:error]).to match(/not suitable/i)
      end

      it "does not requeue delivery of the api request" do
        expect {
          do_request
          participant_outcome.reload
        }.not_to change(participant_outcome, :sent_to_qualified_teachers_api_at?)
      end
    end
  end
end
