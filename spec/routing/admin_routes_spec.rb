require "rails_helper"

RSpec.describe "Admin routes" do
  it { expect(get(api_v3_applications_path)).to route_to("api/v3/applications#index", format: :json) }

  it { expect(get(admin_admins_path)).to route_to("admin/admins#index") }
  it { expect(get("/admin")).to route_to("admin/dashboards#index") }

  it { expect(get(api_guidance_path)).to route_to("api/guidance#index") }
  it { expect(get(api_guidance_page_path(page: "the-page"))).to route_to("api/guidance#show", page: "the-page") }
end
