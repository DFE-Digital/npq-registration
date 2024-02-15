require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#show_tracking_pixels?" do
    let(:cookie_name) { "consented-to-cookies" }

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
      "migration" => nil,
    }.each do |environment, expected_result|
      specify "#{environment}: #{expected_result}" do
        expect(show_otp_code_in_ui(environment, admin)).to eq(expected_result)
      end
    end
  end
end
