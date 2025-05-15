# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DfE Analytics", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }

  context "when DfE Analytics is enabled" do
    before { Flipper.enable(Feature::DFE_ANALYTICS_ENABLED) }

    it "does send DfE Analytics web request events" do
      expect { get root_path }.to have_sent_analytics_event_types(:web_request)
    end

    it "does send DfE Analytics API request events" do
      expect { api_get "/api/v3/npq-applications" }.to have_sent_analytics_event_types(:web_request)
    end

    it "sends a DfE Analytics custom event for API requests" do
      # couldn't get
      #   expect { perform_enqueued_jobs { api_get("/api/v3/npq-applications") } }.to have_sent_analytics_event_types(:persist_api_request)
      # to work
      expect(StreamAPIRequestsToBigQueryJob).to receive(:perform_later)
      perform_enqueued_jobs do
        api_get "/api/v3/npq-applications"
      end
      # expect { perform_enqueued_jobs { api_get("/api/v3/npq-applications") } }.to have_sent_analytics_event_types(:persist_api_request)
      # expect { api_get("/api/v3/npq-applications") }.to have_sent_analytics_event_types(:persist_api_request)
    end

    it "does not send DfE Analytics web request events for healthcheck" do
      expect { get "/healthcheck" }.not_to have_sent_analytics_event_types(:web_request)
    end
  end

  context "when DfE Analytics is disabled" do
    before { Flipper.disable(Feature::DFE_ANALYTICS_ENABLED) }

    it "does not send DfE Analytics web request events" do
      expect { get root_path }.not_to have_sent_analytics_event_types(:web_request)
    end

    it "does not send DfE Analytics API request events" do
      expect { api_get "/api/v3/npq-applications" }.not_to have_sent_analytics_event_types(:web_request)
    end

    it "does not send DfE Analytics web request events for healthcheck" do
      expect { get "/healthcheck" }.not_to have_sent_analytics_event_types(:web_request)
    end
  end
end
