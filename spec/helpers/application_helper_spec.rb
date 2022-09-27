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
end
