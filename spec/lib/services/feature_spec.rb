require "rails_helper"

RSpec.describe Services::Feature do
  describe "#registration_closed?" do
    let(:start_time) { Services::Feature::REGISTRATION_CLOSE_DATE }
    let(:end_time)   { Services::Feature::REGISTRATION_OPEN_DATE }

    before do
      allow(Services::Feature).to receive(:features_enabled?).and_return(true)
      allow(ENV).to receive(:fetch).with("REGISTRATION_CLOSED", "false").and_return("false")
    end

    context "before the closure period" do
      before { travel_to start_time - 1 }

      it "returns false" do
        expect(described_class.registration_closed?).to eql(false)
      end

      context "when REGISTRATION_CLOSED env variable is set" do
        before do
          allow(ENV).to receive(:fetch).with("REGISTRATION_CLOSED", "false").and_return("true")
        end

        it "returns true" do
          expect(described_class.registration_closed?).to eql(true)
        end
      end
    end

    context "during the closure period" do
      before { travel_to start_time }

      it "returns true" do
        expect(described_class.registration_closed?).to eql(true)
      end

      context "when REGISTRATION_CLOSED env variable is set" do
        before do
          allow(ENV).to receive(:fetch).with("REGISTRATION_CLOSED", "false").and_return("true")
        end

        it "returns true" do
          expect(described_class.registration_closed?).to eql(true)
        end
      end
    end

    context "after the closure period" do
      before { travel_to end_time + 1 }

      it "returns false" do
        expect(described_class.registration_closed?).to eql(false)
      end

      context "when REGISTRATION_CLOSED env variable is set" do
        before do
          allow(ENV).to receive(:fetch).with("REGISTRATION_CLOSED", "false").and_return("true")
        end

        it "returns true" do
          expect(described_class.registration_closed?).to eql(true)
        end
      end
    end
  end
end
