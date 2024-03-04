require "rails_helper"

RSpec.describe "NPQ separation routes" do
  let(:api_enabled) { true }
  let(:admin_portal_enabled) { true }
  let(:migration_enabled) { true }

  before do
    allow(Rails.application.config).to receive(:npq_separation) do
      {
        api_enabled:,
        admin_portal_enabled:,
        migration_enabled:,
      }
    end
  end

  it { expect(get(api_v1_applications_path)).to route_to("api/v1/applications#index", format: :json) }
  it { expect(get(api_v2_applications_path)).to route_to("api/v2/applications#index", format: :json) }
  it { expect(get(api_v3_applications_path)).to route_to("api/v3/applications#index", format: :json) }
  it { expect(get(npq_separation_admin_admins_path)).to route_to("npq_separation/admin/admins#index") }
  it { expect(get(npq_separation_migration_migrations_path)).to route_to("npq_separation/migration/migrations#index") }

  context "when api_enabled is false" do
    let(:api_enabled) { false }

    it { expect(get(api_v1_applications_path)).not_to be_routable }
    it { expect(get(api_v2_applications_path)).not_to be_routable }
    it { expect(get(api_v3_applications_path)).not_to be_routable }

    it { expect(get(npq_separation_admin_admins_path)).to be_routable }
    it { expect(get(npq_separation_migration_migrations_path)).to be_routable }
  end

  context "when admin_portal_enabled is false" do
    let(:admin_portal_enabled) { false }

    it { expect(get(npq_separation_admin_admins_path)).not_to be_routable }

    it { expect(get(api_v1_applications_path)).to be_routable }
    it { expect(get(api_v2_applications_path)).to be_routable }
    it { expect(get(api_v3_applications_path)).to be_routable }
    it { expect(get(npq_separation_migration_migrations_path)).to be_routable }
  end

  context "when migration_enabled is false" do
    let(:migration_enabled) { false }

    it { expect(get(npq_separation_migration_migrations_path)).not_to be_routable }

    it { expect(get(api_v1_applications_path)).to be_routable }
    it { expect(get(api_v2_applications_path)).to be_routable }
    it { expect(get(api_v3_applications_path)).to be_routable }
    it { expect(get(npq_separation_admin_admins_path)).to be_routable }
  end
end
