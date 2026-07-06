# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate limiting" do
  include Helpers::JourneyHelper

  let(:ip) { "1.2.3.4" }
  let(:other_ip) { "9.8.7.6" }

  before do
    set_request_ip(ip)
  end

  [
    "/api/guidance",
    "/api/docs/v3",
  ].each do |public_api_path|
    context "when requesting the public API path #{public_api_path}" do
      let(:path) { public_api_path }

      it_behaves_like "a rate limited endpoint", "public API requests by ip" do
        def perform_request
          get path
        end

        def change_condition
          set_request_ip(other_ip)
        end
      end
    end
  end

  [
    Rails.application.routes.url_helpers.session_wizard_show_path("sign-in"),
    Rails.application.routes.url_helpers.session_wizard_show_path("sign-in-code"),
  ].each do |protected_path|
    it_behaves_like "a rate limited endpoint", "protected routes (hitting external services)" do
      let(:path) { protected_path }

      def perform_request
        get path
      end

      def change_condition
        set_request_ip(other_ip)
      end
    end
  end

  it_behaves_like "a rate limited endpoint", "API get an identity webhook message requests by ip" do
    before do
      default_headers["X-Hub-Signature-256"] = "signature"
      allow(GetAnIdentityService::Webhooks::SignatureVerifier).to receive(:call).with(anything).and_return(true)
    end

    def perform_request
      post api_v1_get_an_identity_webhook_messages_path
    end

    def change_condition
      set_request_ip(other_ip)
    end
  end

  it_behaves_like "a rate limited endpoint", "API TeacherAuth webhook message requests by ip" do
    before { allow(Linzer).to receive(:verify!).and_return(true) }

    def perform_request
      post api_teaching_record_system_v1_webhook_messages_path,
           params: { message: "test" }.to_json,
           headers: { "ce-time" => Time.current.to_s }
    end

    def change_condition
      set_request_ip(other_ip)
    end
  end

  it_behaves_like "a rate limited endpoint", "API requests by auth token" do
    let(:lead_provider) { create(:lead_provider) }
    let(:other_lead_provider) { create(:lead_provider) }
    let(:auth_token) { APIToken.create_with_random_token!(lead_provider:) }
    let(:other_auth_token) { APIToken.create_with_random_token!(lead_provider: other_lead_provider) }

    before { set_auth_token(auth_token) }

    def perform_request
      get api_v3_applications_path
    end

    def change_condition
      set_auth_token(other_auth_token)
    end
  end

  it_behaves_like "a rate limited endpoint", "non-API requests by ip" do
    def perform_request
      get root_path
    end

    def change_condition
      set_request_ip(other_ip)
    end
  end

  it_behaves_like "a rate limited endpoint", "catch all requests by ip" do
    def perform_request
      get root_path
    end

    def change_condition
      set_request_ip(other_ip)
    end
  end

  describe "throttle configuration" do
    it "limits protected routes to 10 requests per 5 minutes" do
      expect(Rack::Attack.throttles["protected routes (hitting external services)"]).to have_attributes(limit: 10, period: 5.minutes)
    end

    it "limits API get an identity webhook messages to 100 requests per 5 minutes" do
      expect(Rack::Attack.throttles["API get an identity webhook message requests by ip"]).to have_attributes(limit: 100, period: 5.minutes)
    end

    it "limits API TeacherAuth webhook messages to 100 requests per 5 minutes" do
      expect(Rack::Attack.throttles["API TeacherAuth webhook message requests by ip"]).to have_attributes(limit: 100, period: 5.minutes)
    end

    it "limits API requests by auth token to 1000 requests per 5 minutes" do
      expect(Rack::Attack.throttles["API requests by auth token"]).to have_attributes(limit: 1000, period: 5.minutes)
    end

    it "limits public API requests by ip to 300 requests per 5 minutes" do
      expect(Rack::Attack.throttles["public API requests by ip"]).to have_attributes(limit: 300, period: 5.minutes)
    end

    it "limits non-API requests by ip to 300 requests per 5 minutes" do
      expect(Rack::Attack.throttles["non-API requests by ip"]).to have_attributes(limit: 300, period: 5.minutes)
    end

    it "limits catch all requests by ip to 1500 requests per 5 minutes" do
      expect(Rack::Attack.throttles["catch all requests by ip"]).to have_attributes(limit: 1500, period: 5.minutes)
    end
  end

  def set_request_ip(request_ip)
    default_headers[:REMOTE_ADDR] = request_ip
  end

  def set_auth_token(token)
    default_headers[:Authorization] = "Bearer #{token}"
  end
end
