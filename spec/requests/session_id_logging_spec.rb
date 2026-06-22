# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Session ID logging", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }

  it "stores a session id once a request has been made" do
    get root_path

    expect(session[:log_session_id]).to be_present
  end

  it "keeps the same session id across requests in the same session" do
    get root_path
    first_id = session[:log_session_id]

    get root_path

    expect(session[:log_session_id]).to eq(first_id)
  end

  it "sends the session id to Sentry" do
    allow(Sentry).to receive(:set_tags)

    get root_path

    expect(Sentry).to have_received(:set_tags).with(session_id: session[:log_session_id])
  end

  it "add session id to log lines" do
    allow(SemanticLogger).to receive(:tagged).and_call_original

    get root_path

    expect(SemanticLogger).to have_received(:tagged).with(session_id: session[:log_session_id])
  end
end
