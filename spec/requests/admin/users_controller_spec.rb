require "rails_helper"

RSpec.describe Admin::UsersController, type: :request do
  include Helpers::RequestAdminLogin

  before { sign_in_as_admin }

  describe "/admin/users" do
    subject do
      get admin_users_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "/admin/users/{id}" do
    let(:user_id) { create(:user).id }

    subject do
      get admin_user_path(user_id)
      response
    end

    it { is_expected.to have_http_status(:ok) }

    context "when the user cannot be found", :exceptions_app do
      let(:user_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
