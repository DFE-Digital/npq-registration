require "rails_helper"

RSpec.describe Migration::ParityCheck::TokenProvider do
  let(:instance) { described_class.new }

  before do
    LeadProvider.all.find_each do |lead_provider|
      create(:ecf_migration_npq_lead_provider, id: lead_provider.ecf_id)
    end
  end

  describe "#generate!" do
    subject(:tokens_by_lead_provider) { instance.generate! }

    it { is_expected.to be_present }
    it { expect(tokens_by_lead_provider.keys).to match_array(LeadProvider.pluck(:ecf_id)) }

    it "generates valid ECF tokens" do
      tokens_by_lead_provider.each do |ecf_id, tokens|
        cpd_lead_provider = Migration::Ecf::NpqLeadProvider.find(ecf_id).cpd_lead_provider

        expect(Migration::Ecf::LeadProviderAPIToken.find_by_unhashed_token(tokens[:ecf]).cpd_lead_provider).to eq(cpd_lead_provider)
      end
    end

    it "generates valid NPQ tokens" do
      tokens_by_lead_provider.each do |ecf_id, tokens|
        lead_provider = LeadProvider.find_by(ecf_id:)

        expect(APIToken.find_by_unhashed_token(tokens[:npq]).lead_provider).to eq(lead_provider)
      end
    end

    context "when not running in the test environment" do
      before { allow(Rails).to receive(:env) { "migration".inquiry } }

      it "generates valid ECF tokens" do
        tokens_by_lead_provider.each do |ecf_id, tokens|
          cpd_lead_provider = Migration::Ecf::NpqLeadProvider.find(ecf_id).cpd_lead_provider

          expect(Migration::Ecf::LeadProviderAPIToken.find_by_unhashed_token(tokens[:ecf]).cpd_lead_provider).to eq(cpd_lead_provider)
        end
      end
    end

    context "when the parity check is disabled" do
      before do
        allow(Rails.application.config).to receive(:npq_separation).and_return({
          parity_check: {
            enabled: false,
          },
        })
      end

      it { expect { tokens_by_lead_provider }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
