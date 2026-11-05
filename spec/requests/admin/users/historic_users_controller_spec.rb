require "rails_helper"

RSpec.describe Admin::Users::HistoricUsersController, type: :request do
  include Helpers::RequestAdminLogin

  before { sign_in_as_admin }

  describe "/admin/users/historic/{trn}" do
    subject do
      get admin_historic_user_path("1234567")
      response
    end

    context "when there are legacy outcomes for the TRN" do
      before { create(:legacy_passed_participant_outcome, trn: "1234567") }

      it { is_expected.to have_http_status(:ok) }
    end

    context "when there are no legacy outcomes for the TRN", :exceptions_app do
      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
