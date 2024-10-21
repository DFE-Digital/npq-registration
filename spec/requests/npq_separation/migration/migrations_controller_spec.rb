require "rails_helper"

RSpec.describe NpqSeparation::Migration::MigrationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before do
    allow(Migration::Coordinator).to receive(:prepare_for_migration)
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
        expect(Migration::Coordinator).to have_received(:prepare_for_migration)
        expect(MigrationJob).to have_received(:perform_later)
      end
    end
  end

  describe("download_report") do
    let(:data_migration1) { create(:data_migration, :completed, model: :model) }
    let(:data_migration2) { create(:data_migration, :completed, model: :model) }
    let(:make_request) { get(download_report_npq_separation_migration_migrations_path(:model)) }
    let(:failure_manager_double1) { instance_double(Migration::FailureManager) }
    let(:failure_manager_double2) { instance_double(Migration::FailureManager) }
    let!(:incomplete_data_migration) { create(:data_migration, model: :model) }

    before do
      allow(Migration::FailureManager).to receive(:new).with(data_migration: data_migration1).and_return(failure_manager_double1)
      allow(failure_manager_double1).to receive(:all_failures_hash).and_return({ "Test failure 1" => %w[123456], "Test failure 2" => %w[789010] })

      allow(Migration::FailureManager).to receive(:new).with(data_migration: data_migration2).and_return(failure_manager_double2)
      allow(failure_manager_double2).to receive(:all_failures_hash).and_return({ "Test failure 1" => %w[789123], "Test failure 3" => %w[456756] })

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

        expect(yaml["Test failure 1"]).to eq(%w[123456 789123])
        expect(yaml["Test failure 2"]).to eq(%w[789010])
        expect(yaml["Test failure 3"]).to eq(%w[456756])
      end

      it "ignores incomplete data migrations" do
        expect(Migration::FailureManager).not_to have_received(:new).with(data_migration: incomplete_data_migration)
      end
    end
  end
end
