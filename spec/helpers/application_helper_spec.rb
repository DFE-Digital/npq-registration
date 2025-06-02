require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  include GovukComponentsHelper

  shared_examples "boolean tag" do
    it "is a red tag with 'No' when bool is false" do
      expect(boolean_red_green_tag(false)).to have_css("strong.govuk-tag.govuk-tag--red", text: "No")
    end

    it "is a green tag with 'Yes' when bool is true" do
      expect(boolean_red_green_tag(true)).to have_css("strong.govuk-tag.govuk-tag--green", text: "Yes")
    end

    it "allows custom text to be set" do
      expect(boolean_red_green_tag(true, "Totally")).to have_css("strong.govuk-tag", text: "Totally")
    end
  end

  describe "#show_tracking_pixels?" do
    before do
      allow(Rails.application.config.x)
        .to receive(:tracking_pixels_enabled).and_return(pixels_enabled)
    end

    let(:cookie_name) { "consented-to-cookies" }

    context "when enabled in configuration" do
      let(:pixels_enabled) { true }

      context "when cookies haven't been consented to" do
        specify "tracking pixels are disabled" do
          expect(show_tracking_pixels?).to be(false)
        end
      end

      context "when cookies have been consented to" do
        specify "tracking pixels are enabled" do
          cookies[cookie_name] = "accept"
          expect(show_tracking_pixels?).to be(true)
          cookies.delete(cookie_name)
        end
      end
    end

    context "when disabled by configuration" do
      let(:pixels_enabled) { false }

      specify "tracking pixels are enabled" do
        cookies[cookie_name] = "accept"
        expect(show_tracking_pixels?).to be(false)
        cookies.delete(cookie_name)
      end
    end
  end

  describe "#show_otp_code_in_ui?" do
    let(:otp_hash) { 123_456 }
    let(:admin) { build(:admin, otp_hash:) }

    otp_snippet = "<p>OTP code: 123456</p>".html_safe

    {
      "development" => otp_snippet,
      "staging" => otp_snippet,
      "review" => otp_snippet,
      "sandbox" => nil,
      "production" => nil,
    }.each do |environment, expected_result|
      specify "#{environment}: #{expected_result}" do
        expect(show_otp_code_in_ui(environment, admin)).to eq(expected_result)
      end
    end
  end

  describe "#boolean_red_green_tag" do
    include_examples "boolean tag"
  end

  describe "#boolean_red_green_nil_tag" do
    include_examples "boolean tag"

    it "returns an en dash when bool is nil" do
      expect(boolean_red_green_nil_tag(nil)).to eq("–")
    end
  end

  describe "#join_with_commas" do
    it "returns arguments correctly formated" do
      expect(join_with_commas("a", "b", "c")).to eq("a, b, c")
      expect(join_with_commas("a", "", "c")).to eq("a, c")
      expect(join_with_commas("a", nil, "c")).to eq("a, c")
    end
  end

  describe "#trn_verified_badge" do
    subject { trn_verified_badge(user) }

    context "when the user is nil" do
      let(:user) { nil }

      it { is_expected.to be_nil }
    end

    context "when the TRN is auto verified" do
      let(:user) { build(:user, trn_verified: true, trn_auto_verified: true) }

      it "return a green tag with 'Verified - automatically'" do
        expect(subject).to have_css("strong.govuk-tag.govuk-tag--green", text: "Verified")
        expect(subject).to have_text(" - automatically")
      end
    end

    context "when the TRN is manually verified" do
      let(:user) { build(:user, trn_verified: true, trn_auto_verified: false) }

      it "returns a green tag with 'Verified - manually'" do
        expect(subject).to have_css("strong.govuk-tag.govuk-tag--green", text: "Verified")
        expect(subject).to have_text(" - manually")
      end
    end

    context "when the TRN is not verified" do
      let(:user) { build(:user, trn_verified: false) }

      it "return a red tag with 'Not verified'" do
        expect(subject).to have_css("strong.govuk-tag.govuk-tag--red", text: "Not verified")
      end
    end
  end
end
