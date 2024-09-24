require "rails_helper"

RSpec.describe Feature do
  describe "#registration_closed?" do
    context 'with Flipper flag "Registration open" turned on' do
      before do
        Flipper.enable(Feature::REGISTRATION_OPEN)
      end

      it "returns true" do
        expect(described_class.registration_closed?(nil)).to be false
      end
    end

    context 'with Flipper flag "Registration open" turned off' do
      before do
        Flipper.disable(Feature::REGISTRATION_OPEN)
      end

      it "returns false" do
        expect(described_class.registration_closed?(nil)).to be true
      end
    end
  end

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
