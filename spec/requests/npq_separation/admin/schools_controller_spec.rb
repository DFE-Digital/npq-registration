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
end
