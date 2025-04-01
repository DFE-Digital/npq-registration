# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::GuidanceController do
  subject { response }

  describe "#index" do
    before { get api_guidance_path }

    it { is_expected.to have_http_status :success }
    it { expect(response.headers).to include "cache-control" => "no-store" }
  end

  describe "#show" do
    context "with known page" do
      before { get api_guidance_page_path(page: "how-to-guides/how-npqs-work") }

      it { is_expected.to have_http_status :success }
      it { expect(response.headers).to include "cache-control" => "no-store" }
    end

    context "with unknown page" do
      let(:get_page) { get api_guidance_page_path(page: "unknown") }

      it { expect { get_page }.to raise_exception ActionView::MissingTemplate }
    end

    context "with non-guidance page" do
      let(:get_page) { get api_guidance_page_path(page: "../../errors/not_found") }

      it { expect { get_page }.to raise_exception ActionView::MissingTemplate }
    end
  end
end
