# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CSP Reports Controller" do
  describe "CSP violation reporting" do
    subject { response }

    let(:params) { { "csp-report" => { "blocked-uri" => "https://malicious.com/script.js" } } }

    around do |example|
      ActionController::Base.allow_forgery_protection = true
      example.run
      ActionController::Base.allow_forgery_protection = false
    end

    before do
      allow(Rails.logger).to receive(:error)
      post csp_reports_path, params: params.to_json
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(Rails.logger).to have_received(:error).with(params).once }

    describe "when called without a csp-report" do
      let(:params) { { other: "payload" } }

      it { is_expected.to have_http_status(:success) }
      it { expect(Rails.logger).not_to have_received(:error) }
    end

    describe "when the csp-report contains keys not in our whitelist" do
      let(:params) { { "csp-report" => { "blocked-uri" => "https://malicious.com/script.js", "random" => "information" } } }
      let(:expected_report) { params["csp-report"].slice("blocked-uri") }

      it { expect(Rails.logger).not_to have_received(:error).with(params) }
      it { expect(Rails.logger).to have_received(:error).with({ "csp-report" => expected_report }).once }
    end
  end
end
