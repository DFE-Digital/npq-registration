require "rails_helper"

class ControllerWithLoggerPayload
  prepend API::LoggerPayload

  def initialize(s = 200)
    @response_status = s
  end

  def current_lead_provider
    OpenStruct.new(
      class: LeadProvider,
      id: 9999,
      name: "Best Provider",
    )
  end

  def request
    OpenStruct.new(
      query_parameters: { page: 5 },
      env: {
        "HTTP_VERSION" => "VERSION_123",
        "HTTP_HOST" => "HOST_123",
        "HTTP_USER_AGENT" => "AGENT_123",
        "HTTP_ACCEPT" => "ACCEPT_123",
        "HTTP_ACCEPT_ENCODING" => "ENCODING_123",
        "HTTP_CONNECTION" => "CONN_123",
        "HTTP_CACHE_CONTROL" => "CACHE_123",
        "QUERY_STRING" => "STRING_123",

        "SOMETHING_ELSE" => "XXX123",
      },
      raw_post: "RAW_POST",
    )
  end

  def response
    OpenStruct.new(
      headers: {
        "HEADER1" => "123",
        "HEADER2" => "321",
      },
      status: @response_status,
      body: "RAW_BODY",
    )
  end

  def append_info_to_payload(payload); end
end

RSpec.describe API::LoggerPayload do
  subject { ControllerWithLoggerPayload.new(response_status) }

  let(:payload) { {} }

  describe "#append_info_to_payload" do
    context "when response status 200" do
      let(:response_status) { 200 }

      it "appends payload data" do
        subject.append_info_to_payload(payload)

        expect(payload[:current_user_class]).to eq("LeadProvider")
        expect(payload[:current_user_id]).to eq(9999)
        expect(payload[:current_user_name]).to eq("Best Provider")

        expect(payload[:query_params]).to eq({ page: 5 }.to_json)

        expect(payload[:request_headers]).to eq({
          "HTTP_VERSION" => "VERSION_123",
          "HTTP_HOST" => "HOST_123",
          "HTTP_USER_AGENT" => "AGENT_123",
          "HTTP_ACCEPT" => "ACCEPT_123",
          "HTTP_ACCEPT_ENCODING" => "ENCODING_123",
          "HTTP_CONNECTION" => "CONN_123",
          "HTTP_CACHE_CONTROL" => "CACHE_123",
          "QUERY_STRING" => "STRING_123",
        }.to_json)
        expect(payload[:request_body]).to eq("RAW_POST")

        expect(payload[:response_headers]).to eq({
          "HEADER1" => "123",
          "HEADER2" => "321",
        }.to_json)

        expect(payload[:response_body]).to be_nil
      end
    end

    context "when response status 400" do
      let(:response_status) { 400 }

      it "includes response_body" do
        subject.append_info_to_payload(payload)

        expect(payload[:current_user_class]).to eq("LeadProvider")
        expect(payload[:current_user_id]).to eq(9999)
        expect(payload[:current_user_name]).to eq("Best Provider")

        expect(payload[:query_params]).to eq({ page: 5 }.to_json)

        expect(payload[:request_headers]).to eq({
          "HTTP_VERSION" => "VERSION_123",
          "HTTP_HOST" => "HOST_123",
          "HTTP_USER_AGENT" => "AGENT_123",
          "HTTP_ACCEPT" => "ACCEPT_123",
          "HTTP_ACCEPT_ENCODING" => "ENCODING_123",
          "HTTP_CONNECTION" => "CONN_123",
          "HTTP_CACHE_CONTROL" => "CACHE_123",
          "QUERY_STRING" => "STRING_123",
        }.to_json)
        expect(payload[:request_body]).to eq("RAW_POST")

        expect(payload[:response_headers]).to eq({
          "HEADER1" => "123",
          "HEADER2" => "321",
        }.to_json)

        expect(payload[:response_body]).to eq("RAW_BODY")
      end
    end
  end
end