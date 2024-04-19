require "rails_helper"

RSpec.describe NpqSeparation::Admin::SchoolsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "/npq_separation/admin/schools" do
    subject do
      get npq_separation_admin_schools_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "/npq_separation/admin/schools/{id}" do
    let(:school_id) { create(:school).id }

    subject do
      get npq_separation_admin_school_path(school_id)
      response
    end

    it { is_expected.to have_http_status(:ok) }

    context "when the school cannot be found", exceptions_app: true do
      let(:school_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
