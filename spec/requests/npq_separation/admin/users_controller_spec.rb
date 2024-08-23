require "rails_helper"

RSpec.describe NpqSeparation::Admin::UsersController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "/npq_separation/admin/users" do
    subject do
      get npq_separation_admin_users_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "/npq_separation/admin/users/{id}" do
    let(:user_id) { create(:user).id }

    subject do
      get npq_separation_admin_user_path(user_id)
      response
    end

    it { is_expected.to have_http_status(:ok) }

    context "when the user cannot be found", :exceptions_app do
      let(:user_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
