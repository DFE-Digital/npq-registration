require "rails_helper"

RSpec.describe Feature do
  describe "#registration_closed?" do
    context 'with Flipper flag "Registration open" turned on' do
      before do
        Flipper.enable(Feature::REGISTRATION_OPEN)
      end

      it "returns true" do
        expect(described_class.registration_closed?(nil)).to eq false
      end
    end

    context 'with Flipper flag "Registration open" turned off' do
      before do
        Flipper.disable(Feature::REGISTRATION_OPEN)
      end

      it "returns false" do
        expect(described_class.registration_closed?(nil)).to eq true
      end
    end
  end
end
