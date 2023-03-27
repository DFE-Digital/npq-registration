require "rails_helper"

RSpec.describe Services::Feature do
  describe "#registration_closed?" do
    context 'with Flipper flag "Registration closed" turned on' do
      before do
        Flipper.enable(Services::Feature::REGISTRATION_CLOSED_KEY)
      end

      it "returns true" do
        expect(described_class.registration_closed?).to eq true
      end
    end

    context 'with Flipper flag "Registration closed" turned off' do
      before do
        Flipper.disable(Services::Feature::REGISTRATION_CLOSED_KEY)
      end

      it "returns false" do
        expect(described_class.registration_closed?).to eq false
      end
    end
  end
end
