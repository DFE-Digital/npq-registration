require "rails_helper"

RSpec.describe NpqSeparation::Migration::MigrationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before do
    allow(Migration::Migrator).to receive(:prepare_for_migration)
    allow(MigrationJob).to receive(:perform_later)
    sign_in_as_admin(super_admin:)
  end

  describe("index") do
    let(:make_request) { get(npq_separation_migration_migrations_path) }

    before { make_request }

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

    before { make_request }

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

  describe("download_report") do
    let(:data_migration) { create(:data_migration) }
    let(:make_request) { get(download_report_npq_separation_migration_migrations_path(data_migration.id)) }
    let(:failure_manager_double) { instance_double(Migration::FailureManager) }

    before do
      allow(Migration::FailureManager).to receive(:new).with(data_migration:).and_return(failure_manager_double)
      allow(failure_manager_double).to receive(:all_failures).and_return({ "Test failure 1" => %w[123456], "Test failure 2" => %w[789010] }.to_yaml)

      make_request
    end

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

      it "sends data correctly" do
        expect(response).to be_successful

        yaml = YAML.load(response.body)

        expect(yaml["Test failure 1"].first).to eq("123456")
        expect(yaml["Test failure 2"].first).to eq("789010")
      end
    end
  end
end
