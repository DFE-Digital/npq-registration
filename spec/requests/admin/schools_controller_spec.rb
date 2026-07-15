require "rails_helper"

RSpec.describe Admin::SchoolsController, type: :request do
  include Helpers::RequestAdminLogin

  before { sign_in_as_admin }

  describe "/admin/schools" do
    subject do
      get admin_schools_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end
end
