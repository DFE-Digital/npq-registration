require "rails_helper"

RSpec.describe "NPQ separation routes" do
  it { expect(get(api_v1_applications_path)).to route_to("api/v1/applications#index", format: :json) }
  it { expect(get(api_v2_applications_path)).to route_to("api/v2/applications#index", format: :json) }
  it { expect(get(api_v3_applications_path)).to route_to("api/v3/applications#index", format: :json) }

  it { expect(get(npq_separation_admin_admins_path)).to route_to("npq_separation/admin/admins#index") }

  it { expect(get(api_guidance_path)).to route_to("api/guidance#index") }
  it { expect(get(api_guidance_page_path(page: "the-page"))).to route_to("api/guidance#show", page: "the-page") }
end
