require "rails_helper"

RSpec.describe NpqSeparation::Migration::MigrationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before do
    allow(Migration::Migrator).to receive(:prepare_for_migration)
    allow(MigrationJob).to receive(:perform_later)
    sign_in_as_admin(super_admin:)
    make_request
  end

  describe("index") do
    let(:make_request) { get(npq_separation_migration_migrations_path) }

    context "when not signed in as a super admin" do
      let(:super_admin) { false }

      it { expect(response).to redirect_to(sign_in_path) }

      it "asks the user to sign in as an admin" do
        follow_redirect!
        expect(response.body).to include("Sign in with your administrator account")
      end
    end

    context "when signed in as a super admin" do
      let(:super_admin) { true }

      it { expect(response).to be_successful }
    end
  end

  describe("create") do
    let(:make_request) { post(npq_separation_migration_migrations_path) }

    context "when not signed in as a super admin" do
      let(:super_admin) { false }

      it { expect(response).to redirect_to(sign_in_path) }

      it "asks the user to sign in as an admin" do
        follow_redirect!
        expect(response.body).to include("Sign in with your administrator account")
      end
    end

    context "when signed in as a super admin" do
      let(:super_admin) { true }

      it "triggers a migration" do
        expect(response).to redirect_to(npq_separation_migration_migrations_path)
        expect(Migration::Migrator).to have_received(:prepare_for_migration)
        expect(MigrationJob).to have_received(:perform_later)
      end
    end
  end
end
