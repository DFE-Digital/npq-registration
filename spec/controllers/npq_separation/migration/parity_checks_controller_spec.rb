require "rails_helper"

RSpec.describe NpqSeparation::Migration::ParityChecksController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before do
    allow(Migration::ParityCheck).to receive(:prepare!)
    allow(ParityCheckJob).to receive(:perform_later)
    sign_in_as_admin(super_admin:)
  end

  describe("index") do
    let(:make_request) { get(npq_separation_migration_parity_checks_path) }

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
    let(:make_request) { post(npq_separation_migration_parity_checks_path) }

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

      it "triggers a parity check" do
        expect(response).to redirect_to(npq_separation_migration_parity_checks_path)
        expect(Migration::ParityCheck).to have_received(:prepare!)
        expect(ParityCheckJob).to have_received(:perform_later)
      end
    end
  end

  describe("response_comparison") do
    let(:comparison) { create(:response_comparison, :different) }
    let(:make_request) { get(response_comparison_npq_separation_migration_parity_checks_path(comparison)) }

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

      context "when the response comparison is equal", :exceptions_app do
        let(:comparison) { create(:response_comparison, :equal) }

        it { expect(response).to be_not_found }
      end

      context "when the response comparison is not found", :exceptions_app do
        let(:comparison) { OpenStruct.new(id: -1) }

        it { expect(response).to be_not_found }
      end
    end
  end
end
