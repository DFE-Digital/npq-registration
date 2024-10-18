require "rails_helper"

RSpec.describe Migration::ParityCheck::TokenProvider do
  before do
    create_list(:lead_provider, 3)

    allow(Rails.application.config).to receive(:npq_separation).and_return({
      parity_check: {
        enabled:,
      },
    })

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PARITY_CHECK_KEYS").and_return(keys.to_json) if keys
  end

  let(:instance) { described_class.new }

  describe "#generate!" do
    subject(:generate) { instance.generate! }

    context "when the parity check is enabled" do
      let(:enabled) { true }

      context "when the keys are not present" do
        let(:keys) { nil }

        it { expect { generate }.not_to change(APIToken, :count) }
      end

      context "when the keys are present" do
        let(:keys) do
          LeadProvider.all.each_with_object({}) do |lead_provider, hash|
            hash[lead_provider.ecf_id] = SecureRandom.uuid
          end
        end

        it { expect { generate }.to change(APIToken, :count).by(LeadProvider.count) }

        it "generates valid tokens for each lead provider" do
          generate

          LeadProvider.find_each do |lead_provider|
            token = instance.token(lead_provider:)
            expect(APIToken.find_by_unhashed_token(token).lead_provider).to eq(lead_provider)
          end
        end
      end
    end

    context "when the parity check is disabled" do
      let(:enabled) { false }
      let(:keys) { {} }

      it { expect { generate }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end

  describe "#token" do
    let(:lead_provider) { create(:lead_provider) }

    subject(:token) { instance.token(lead_provider:) }

    context "when the parity check is enabled" do
      let(:enabled) { true }

      context "when the keys are not present" do
        let(:keys) { nil }

        it { is_expected.to be_nil }
      end

      context "when the keys are present" do
        let(:keys) do
          { lead_provider.ecf_id => "token" }
        end

        it { is_expected.to eq("token") }
      end
    end

    context "when the parity check is disabled" do
      let(:enabled) { false }
      let(:keys) { {} }

      it { expect { token }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
