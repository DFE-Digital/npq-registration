# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::DocumentationController do
  subject { response }

  context "with v1" do
    before { get api_documentation_path(version: "v1") }

    it { is_expected.to have_http_status :success }
    it { expect(response.headers).to include "cache-control" => "no-store" }
  end

  context "with v2" do
    before { get api_documentation_path(version: "v2") }

    it { is_expected.to have_http_status :success }
    it { expect(response.headers).to include "cache-control" => "no-store" }
  end

  context "with v3" do
    before { get api_documentation_path(version: "v3") }

    it { is_expected.to have_http_status :success }
    it { expect(response.headers).to include "cache-control" => "no-store" }
  end

  context "with v4" do
    let(:make_request) { get api_documentation_path(version: "v4") }

    it { expect { make_request }.to raise_exception ActionController::RoutingError }
  end

  context "without version" do
    let(:make_request) { get api_documentation_path(version: "") }

    it { expect { make_request }.to raise_exception ActionController::RoutingError }
  end
end
