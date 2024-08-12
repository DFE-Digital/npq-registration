require "rails_helper"

class ControllerWithLoggerPayload
  prepend API::LoggerPayload

  def initialize(response_status: 200, query_parameters: { page: 5 })
    @response_status = response_status
    @query_parameters = query_parameters
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
      query_parameters: @query_parameters,
      env: {
        "HTTP_HOST" => "HOST_123",
        "HTTP_ACCEPT" => "ACCEPT_123",
        "HTTP_ACCEPT_ENCODING" => "ENCODING_123",
        "HTTP_CONNECTION" => "CONN_123",
        "HTTP_CACHE_CONTROL" => "CACHE_123",

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
  subject { ControllerWithLoggerPayload.new(response_status:) }

  let(:payload) { {} }

  describe "#append_info_to_payload" do
    context "when response status 200" do
      let(:response_status) { 200 }

      it "appends payload data" do
        subject.append_info_to_payload(payload)

        expect(payload[:current_user_class]).to eq("LeadProvider")
        expect(payload[:current_user_id]).to eq(9999)
        expect(payload[:current_user_name]).to eq("Best Provider")

        expect(payload[:request_query_params]).to eq({ page: 5 }.to_json)

        expect(payload[:request_headers]).to eq({
          "HTTP_HOST" => "HOST_123",
          "HTTP_ACCEPT" => "ACCEPT_123",
          "HTTP_ACCEPT_ENCODING" => "ENCODING_123",
          "HTTP_CONNECTION" => "CONN_123",
          "HTTP_CACHE_CONTROL" => "CACHE_123",
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

        expect(payload[:request_query_params]).to eq({ page: 5 }.to_json)

        expect(payload[:request_headers]).to eq({
          "HTTP_HOST" => "HOST_123",
          "HTTP_ACCEPT" => "ACCEPT_123",
          "HTTP_ACCEPT_ENCODING" => "ENCODING_123",
          "HTTP_CONNECTION" => "CONN_123",
          "HTTP_CACHE_CONTROL" => "CACHE_123",
        }.to_json)
        expect(payload[:request_body]).to eq("RAW_POST")

        expect(payload[:response_headers]).to eq({
          "HEADER1" => "123",
          "HEADER2" => "321",
        }.to_json)

        expect(payload[:response_body]).to eq("RAW_BODY")
      end
    end

    context "when request_query_params is empty {}" do
      subject { ControllerWithLoggerPayload.new(query_parameters: {}) }

      it "request_query_params should be nil instead of '{}'" do
        subject.append_info_to_payload(payload)

        expect(payload[:request_query_params]).to be_nil
      end
    end
  end
end
