require "rails_helper"

RSpec.describe Feature do
  describe ".initialize_feature_flags" do
    before do
      Flipper.features.each(&:remove)
      Flipper.add("test")
      Flipper.add(Feature::FEATURE_FLAG_KEYS.first)

      Feature.initialize_feature_flags
    end

    it "removes features whose name is not in FEATURE_FLAG_KEYS" do
      expect(Flipper.features.map(&:name)).to match_array(Feature::FEATURE_FLAG_KEYS)
    end
  end

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

  describe "#registration_disabled?" do
    context "when enabled" do
      before do
        Flipper.enable(Feature::REGISTRATION_DISABLED)
      end

      it "registration_disabled? returns true" do
        expect(described_class.registration_disabled?).to be(true)
      end

      it "registration_enabled? returns false" do
        expect(described_class.registration_enabled?).to be(false)
      end
    end

    context "when disabled" do
      before do
        Flipper.disable(Feature::REGISTRATION_DISABLED)
      end

      it "registration_disabled? returns false" do
        expect(described_class.registration_disabled?).to be(false)
      end

      it "registration_enabled? returns true" do
        expect(described_class.registration_enabled?).to be(true)
      end
    end
  end

  describe "#disable_registration!" do
    it "disables registration" do
      Feature.disable_registration!
      expect(Flipper.enabled?(Feature::REGISTRATION_DISABLED)).to be(true)
    end
  end

  describe "#enable_registration!" do
    it "enables registration" do
      Feature.enable_registration!
      expect(Flipper.enabled?(Feature::REGISTRATION_DISABLED)).to be(false)
    end
  end

  describe "#maintenance_banner" do
    subject { Feature }

    context "when enabled" do
      before { Flipper.enable(Feature::MAINTENANCE_BANNER) }

      it { is_expected.to be_maintenance_banner_enabled }
    end

    context "when disabled" do
      before { Flipper.disable(Feature::MAINTENANCE_BANNER) }

      it { is_expected.not_to be_maintenance_banner_enabled }
    end
  end

  describe ".dfe_analytics_enabled?" do
    context "when disabled" do
      it "returns false" do
        expect(Feature).not_to be_dfe_analytics_enabled
      end
    end

    context "when enabled" do
      before { Flipper.enable(Feature::DFE_ANALYTICS_ENABLED) }

      it "returns true" do
        expect(Feature).to be_dfe_analytics_enabled
      end
    end
  end

  describe ".declarations_require_delivery_partner?" do
    context "when disabled" do
      it "returns false" do
        expect(Feature).not_to be_declarations_require_delivery_partner
      end
    end

    context "when enabled" do
      before { Flipper.enable(Feature::DECLARATIONS_REQUIRE_DELIVERY_PARTNER) }

      it "returns true" do
        expect(Feature).to be_declarations_require_delivery_partner
      end
    end
  end
end
