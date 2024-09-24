require "rails_helper"

RSpec.describe Feature do
  describe "#ecf_api_disabled?" do
    context "when enabled" do
      before do
        Flipper.enable(Feature::ECF_API_DISABLED)
      end

      it "returns true" do
        expect(Feature.ecf_api_disabled?).to be(true)
      end
    end

    context "when disabled" do
      before do
        Flipper.disable(Feature::ECF_API_DISABLED)
      end

      it "returns false" do
        expect(Feature.ecf_api_disabled?).to be(false)
      end
    end
  end
end
