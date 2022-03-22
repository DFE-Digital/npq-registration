require "rails_helper"

RSpec.describe Services::Feature do
  describe "#registration_closed?" do
    let(:start_time) { Services::Feature::REGISTRATION_CLOSED.first }
    let(:end_time)   { Services::Feature::REGISTRATION_CLOSED.last }

    before do
      allow(Services::Feature).to receive(:features_enabled?).and_return(true)
    end

    context "before the closure period" do
      before { travel_to start_time - 1 }

      it "returns false" do
        expect(described_class.registration_closed?).to eql(false)
      end
    end

    context "during the closure period" do
      before { travel_to start_time }

      it "returns true" do
        expect(described_class.registration_closed?).to eql(true)
      end
    end

    # Service doesn't have a re-open date currently.
    #
    # context "after the closure period" do
    #   before { travel_to end_time + 1 }

    #   it "returns false" do
    #     expect(described_class.registration_closed?).to eql(false)
    #   end
    # end
  end
end
