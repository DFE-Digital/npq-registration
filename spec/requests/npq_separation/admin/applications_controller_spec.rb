require "rails_helper"

RSpec.describe NpqSeparation::Admin::ApplicationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "/npq_separation/admin/applications" do
    subject do
      get npq_separation_admin_applications_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "/npq_separation/admin/applications/{id}" do
    let(:application_id) { create(:application).id }

    subject do
      get npq_separation_admin_application_path(application_id)
      response
    end

    it { is_expected.to have_http_status(:ok) }

    context "when the application cannot be found", exceptions_app: true do
      let(:application_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
