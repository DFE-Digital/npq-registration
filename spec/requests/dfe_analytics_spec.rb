# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DfE Analytics", type: :request do
  before { Flipper.enable(Feature::DFE_ANALYTICS_ENABLED) }

  it "does send DFE Analytics web request events" do
    expect { get root_path }.to have_sent_analytics_event_types(:web_request)
  end
end
