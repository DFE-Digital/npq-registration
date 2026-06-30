require "rails_helper"

RSpec.describe Admin::ApplicationsController, type: :request do
  include Helpers::RequestAdminLogin

  before { sign_in_as_admin }

  describe "/admin/applications" do
    before { create(:cohort, :current) }

    subject do
      get admin_applications_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "/admin/applications/{id}" do
    let(:application_id) { create(:application).id }

    subject do
      get admin_application_path(application_id)
      response
    end

    it { is_expected.to have_http_status(:ok) }

    context "when the application cannot be found", :exceptions_app do
      let(:application_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
