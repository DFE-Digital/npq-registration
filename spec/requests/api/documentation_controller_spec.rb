# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::DocumentationController do
  subject { response }

  context "with v3" do
    before { get api_documentation_path(version: "v3") }

    it { is_expected.to have_http_status :success }
    it { expect(response.headers).to include "cache-control" => "no-store" }
  end

  context "with v4" do
    before { get api_documentation_path(version: "v4") }

    it { is_expected.to have_http_status :not_found }
  end

  context "without version" do
    before { get api_documentation_path(version: "") }

    it { is_expected.to have_http_status :not_found }
  end
end
