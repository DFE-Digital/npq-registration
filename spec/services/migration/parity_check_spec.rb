require "rails_helper"

RSpec.describe Migration::ParityCheck do
  let(:token) { "abc123" }
  let(:instance) { described_class.new(token:) }
  let(:enabled) { true }
  let(:ecf_url) { "http://ecf.example.com" }
  let(:npq_url) { "http://npq.example.com" }

  before do
    allow(Rails.application.config).to receive(:npq_separation) do
      {
        parity_check: {
          enabled:,
          ecf_url:,
          npq_url:,
        },
      }
    end
  end

  it { expect(instance.token).to eq(token) }

  describe(".run") do
    subject(:run) { instance.run }

    context "when there are existing comparisons from a previous run" do
      before { create(:parity_check_comparison) }

      it "destroys them" do
        expect { run }.to change(ParityCheckComparison, :count).by(-1)
      end
    end

    context "when the parity check is disabled" do
      let(:enabled) { false }

      it { expect { run }.to raise_error(Migration::ParityCheck::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
