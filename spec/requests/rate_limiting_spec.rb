# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate limiting" do
  let(:ip) { "1.2.3.4" }
  let(:other_ip) { "9.8.7.6" }

  before { set_request_ip(ip) }

  it_behaves_like "a rate limited endpoint", "general requests by ip" do
    def perform_request
      get root_path
    end

    def change_condition
      set_request_ip(other_ip)
    end
  end

  [
    "/api/guidance",
    "/api/docs/v1",
    "/api/docs/v2",
    "/api/docs/v3",
  ].each do |public_api_path|
    context "when requesting the public API path #{public_api_path}" do
      let(:path) { public_api_path }

      it_behaves_like "a rate limited endpoint", "general requests by ip" do
        def perform_request
          get path
        end

        def change_condition
          set_request_ip(other_ip)
        end
      end
    end
  end

  Rack::Attack::PROTECTED_ROUTES.each do |protected_path|
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

  it_behaves_like "a rate limited endpoint", "csp_reports req/ip" do
    def perform_request
      post csp_reports_path, params: {}.to_json
    end

    def change_condition
      set_request_ip(other_ip)
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

  def set_request_ip(request_ip)
    default_headers[:REMOTE_ADDR] = request_ip
  end

  def set_auth_token(token)
    default_headers[:Authorization] = "Bearer #{token}"
  end
end
