# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Monitoring" do
  describe "GET /healthcheck" do
    let(:git_sha) { "911403d" }
    let(:migration_version) { ApplicationRecord.connection.migration_context.current_version }
    let(:response_body) { JSON.parse(perform_request.body, symbolize_names: true) }

    before { allow(ENV).to receive(:[]).with("COMMIT_SHA") { git_sha } }

    subject(:perform_request) do
      get healthcheck_path
      response
    end

    it { is_expected.to be_successful }
    it { expect(response_body[:database]).to match({ connected: true, migration_version:, populated: true }) }
    it { expect(response_body[:git_commit_sha]).to eq(git_sha) }

    context "when the database is not connected" do
      context "when ApplicationRecord#connected? raises an error" do
        before { allow(ApplicationRecord).to receive(:connected?).and_raise(RuntimeError) }

        it { is_expected.to be_server_error }
        it { expect(response_body[:database]).to include({ connected: false, populated: false }) }
      end

      context "when ApplicationRecord#connected? returns false" do
        before { allow(ApplicationRecord).to receive(:connected?).and_return(false) }

        it { is_expected.to be_server_error }
        it { expect(response_body[:database]).to include({ connected: false, populated: false }) }
      end
    end

    context "when the database is not populated" do
      before { Course.destroy_all }

      it { is_expected.to be_server_error }
      it { expect(response_body[:database]).to include({ connected: true, populated: false }) }

      context "when the environment supports refreshing the database via a GitHub action" do
        before { allow(Rails).to receive(:env) { "migration".inquiry } }

        it { is_expected.to be_successful }
        it { expect(response_body[:database]).to include({ connected: true, populated: false }) }
      end
    end
  end
end
