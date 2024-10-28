require "rails_helper"

RSpec.describe "NPQ separation routes" do
  before { allow(Feature).to receive(:ecf_api_disabled?).and_return(true) }

  it { expect(get(api_v1_applications_path)).to route_to("api/v1/applications#index", format: :json) }
  it { expect(get(api_v2_applications_path)).to route_to("api/v2/applications#index", format: :json) }
  it { expect(get(api_v3_applications_path)).to route_to("api/v3/applications#index", format: :json) }

  it { expect(get(npq_separation_admin_admins_path)).to route_to("npq_separation/admin/admins#index") }
  it { expect(get(npq_separation_migration_migrations_path)).to route_to("npq_separation/migration/migrations#index") }

  it { expect(get(api_guidance_path)).to route_to("api/guidance#index") }
  it { expect(get(api_guidance_page_path(page: "the-page"))).to route_to("api/guidance#show", page: "the-page") }
  it { expect(get(download_report_npq_separation_migration_migrations_path("model"))).to route_to("npq_separation/migration/migrations#download_report", model: "model") }

  context "when ecf_api_disabled feature is false" do
    before { allow(Feature).to receive(:ecf_api_disabled?).and_return(false) }

    it { expect(get(api_v1_applications_path)).not_to be_routable }
    it { expect(get(api_v2_applications_path)).not_to be_routable }
    it { expect(get(api_v3_applications_path)).not_to be_routable }

    it { expect(get(npq_separation_admin_admins_path)).not_to be_routable }
    it { expect(get(npq_separation_migration_migrations_path)).not_to be_routable }

    it { expect(get(api_guidance_path)).not_to be_routable }
    it { expect(get(api_guidance_page_path(page: "the-page"))).not_to route_to("api/guidance#show", page: "the-page") }
    it { expect(get(download_report_npq_separation_migration_migrations_path(1))).not_to be_routable }
  end
end
