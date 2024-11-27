# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::Applications::ChangeFundingEligibilitiesController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:application) { create(:application, :accepted) }

  context "when logged in" do
    before { sign_in_as_admin }

    describe "#new" do
      before do
        get new_npq_separation_admin_applications_change_funding_eligibility_path(application)
      end

      it { is_expected.to have_http_status :success }
      xit { is_expected.to have_attributes body: /Change funding eligibility/i }
    end

    describe "#create" do
      before do
        post npq_separation_admin_applications_change_funding_eligibility_path(application, params:)
      end

      let(:params) { {} }

      it { is_expected.to redirect_to npq_separation_admin_application_path(application) }
    end
  end

  context "when not logged in" do
    describe "#new" do
      before { get new_npq_separation_admin_applications_change_funding_eligibility_path(application) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before do
        post npq_separation_admin_applications_change_funding_eligibility_path(application, params: {})
      end

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
