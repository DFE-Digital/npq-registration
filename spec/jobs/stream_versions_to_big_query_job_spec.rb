# frozen_string_literal: true

require "rails_helper"

RSpec.describe StreamVersionsToBigQueryJob, type: :job do
  subject(:job) { described_class.perform_now(user_name, data) }

  let(:analytics_event) { instance_double(DfE::Analytics::Event) }
  let(:user_name) { "Admin 1" }
  let(:analytics_enabled) { true }

  let(:data) do
    {
      "whatever" => "whatever",
      "object_changes" => %w[something something_else],
    }
  end

  before do
    allow(Feature).to receive(:dfe_analytics_enabled?).and_return(analytics_enabled)
    allow(DfE::Analytics::Event).to receive(:new) { analytics_event }
    allow(analytics_event).to receive(:with_type).with(:version) { analytics_event }
    allow(analytics_event).to receive(:with_namespace).with("npq") { analytics_event }
    allow(analytics_event).to receive(:with_user).with(user_name) { analytics_event }
    allow(analytics_event).to receive(:with_data).with(data:) { analytics_event }
  end

  it "sends a DfE::Analytics custom event" do
    expect(DfE::Analytics::SendEvents).to receive(:do).with([analytics_event])

    job
  end

  context "with analytics disabled" do
    let(:analytics_enabled) { false }

    it "does not send the custom event" do
      expect(DfE::Analytics::SendEvents).not_to receive(:do)

      job
    end
  end
end
