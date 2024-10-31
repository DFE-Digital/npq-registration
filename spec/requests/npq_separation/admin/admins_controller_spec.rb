require "rails_helper"

RSpec.describe NpqSeparation::Admin::AdminsController, :ecf_api_disabled, type: :request do
  describe("index") do
    before { get(npq_separation_admin_admins_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
