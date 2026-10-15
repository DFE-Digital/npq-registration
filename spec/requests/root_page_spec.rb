# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Root path" do
  subject { response }

  context "when requesting HTML" do
    before { get root_path }

    it { is_expected.to have_http_status :success }
    it { expect(response.headers).to include "cache-control" => "no-store" }
  end

  context "when accepting any format" do
    before { get root_path, headers: { "Accept" => "*/*" } }

    it { is_expected.to have_http_status :success }
  end

  context "when requesting JSON" do
    before { get root_path, headers: { "Accept" => "application/json" } }

    it { is_expected.to have_http_status :not_acceptable }
  end

  context "when requesting a registration step as JSON" do
    before { get "/registration/start.json" }

    it { is_expected.to have_http_status :not_acceptable }
  end
end
