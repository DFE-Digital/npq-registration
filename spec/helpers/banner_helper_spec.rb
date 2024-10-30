# frozen_string_literal: true

require "rails_helper"

RSpec.describe BannerHelper, type: :helper do
  describe "#maintenance_banner_dismissed?" do
    subject { helper }

    context "when the dismissed_until cookie is not set" do
      it { is_expected.not_to be_maintenance_banner_dismissed }
    end

    context "when the dismissed_until cookie is set to a future value" do
      before { helper.request.cookies[:dismiss_maintenance_banner_until] = 1.day.from_now.to_s }

      it { is_expected.to be_maintenance_banner_dismissed }
    end

    context "when the dismissed_until cookie is set to a past value" do
      before { helper.request.cookies[:dismiss_maintenance_banner_until] = 1.day.ago.to_s }

      it { is_expected.not_to be_maintenance_banner_dismissed }
    end

    context "when the dismissed_until cookie does not contain a valid time" do
      before { helper.request.cookies[:dismiss_maintenance_banner_until] = "1 week from now" }

      it { is_expected.not_to be_maintenance_banner_dismissed }
    end
  end
end
