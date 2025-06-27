# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Monitoring" do
  describe "GET /healthcheck" do
    let(:git_sha) { "911403d" }
    let(:migration_version) { ApplicationRecord.connection_pool.migration_context.current_version }
    let(:response_body) { JSON.parse(perform_request.body, symbolize_names: true) }
    let(:redis_cache) { ActiveSupport::Cache::RedisCacheStore.new(url: "redis://randomhostname:6379/", timeout: 0.2) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("COMMIT_SHA") { git_sha }
      allow(Rails).to receive(:cache).and_return redis_cache
      allow_any_instance_of(Redis).to receive(:ping).and_return "PONG"
    end

    subject(:perform_request) do
      get healthcheck_path
      response
    end

    it { is_expected.to be_successful }
    it { expect(response_body[:database]).to match({ connected: true, migration_version:, populated: true }) }
    it { expect(response_body[:redis]).to be true }
    it { expect(response_body[:git_commit_sha]).to eq(git_sha) }

    context "when the database is not connected" do
      context "when ApplicationRecord#connected? raises an error" do
        before { allow(ApplicationRecord).to receive(:connected?).and_raise(RuntimeError) }

        it { is_expected.to have_http_status :service_unavailable }
        it { expect(response_body[:database]).to include({ connected: false, populated: false }) }
      end

      context "when ApplicationRecord#connected? returns false" do
        before { allow(ApplicationRecord).to receive(:connected?).and_return(false) }

        it { is_expected.to have_http_status :service_unavailable }
        it { expect(response_body[:database]).to include({ connected: false, populated: false }) }
      end
    end

    context "when the database is not populated" do
      before { Course.destroy_all }

      it { is_expected.to have_http_status :service_unavailable }
      it { expect(response_body[:database]).to include({ connected: true, populated: false }) }
    end

    context "when Redis is not connected" do
      before do
        allow_any_instance_of(Redis).to receive(:ping) do
          raise Redis::CannotConnectError, "Could not connect"
        end
      end

      it { is_expected.to have_http_status :service_unavailable }
      it { expect(response_body[:redis]).to be false }
    end
  end

  describe "GET /up" do
    subject { get(up_path) && response }

    it { is_expected.to be_successful }

    context "when database not connected" do
      before { allow(ApplicationRecord).to receive(:connected?).and_return false }

      it { is_expected.to have_http_status :service_unavailable }
    end
  end
end
