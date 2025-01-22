require "rails_helper"

RSpec.describe NpqSeparation::Admin::CohortsController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:cohort)         { create(:cohort) }
  let(:valid_params)   { { cohort: { start_year: 2029, funding_cap: true, registration_start_date: "2029-03-02" } } }
  let(:invalid_params) { { cohort: { start_year: 1066 } } }

  context "when logged in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    describe "#index" do
      before { get npq_separation_admin_cohorts_path }

      it { is_expected.to have_http_status :success }
    end

    describe "#show" do
      before { get npq_separation_admin_cohorts_path(cohort) }

      it { is_expected.to have_http_status :success }
    end

    describe "#new" do
      before { get new_npq_separation_admin_cohort_path }

      it { is_expected.to have_http_status :success }
    end

    describe "#create" do
      before { post npq_separation_admin_cohorts_path, params: valid_params }

      it { is_expected.to redirect_to npq_separation_admin_cohorts_path }

      it "flashes success" do
        expect(flash[:success]).to match(/Cohort created/i)
      end
    end

    describe "#create with invalid params" do
      before { post npq_separation_admin_cohorts_path, params: invalid_params }

      it { is_expected.to have_http_status :unprocessable_entity }
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_path(cohort) }

      it { is_expected.to have_http_status :success }
    end

    describe "#update" do
      before { patch npq_separation_admin_cohort_path(cohort), params: valid_params }

      it { is_expected.to redirect_to npq_separation_admin_cohort_path(cohort) }

      it "flashes success" do
        expect(flash[:success]).to match(/Cohort updated/i)
      end
    end

    describe "#update with invalid params" do
      before { patch npq_separation_admin_cohort_path(cohort), params: invalid_params }

      it { is_expected.to have_http_status :unprocessable_entity }
    end

    describe "#destroy" do
      before { delete npq_separation_admin_cohort_path(cohort) }

      it { is_expected.to have_http_status :success }
    end

    describe "#destroy with confirm" do
      before { delete npq_separation_admin_cohort_path(cohort), params: { confirm: "1" } }

      it { is_expected.to redirect_to npq_separation_admin_cohorts_path }

      it "flashes success" do
        expect(flash[:success]).to match(/Cohort deleted/i)
      end
    end
  end

  context "when logged in as normal admin" do
    before { sign_in_as_admin }

    shared_examples "inaccessible to normal admins" do
      it { is_expected.to redirect_to npq_separation_admin_cohorts_path }

      it "flashes the correct error" do
        expect(flash[:error]).to match(/You must be a super admin to change cohorts/i)
      end
    end

    describe "#index" do
      before { get npq_separation_admin_cohorts_path }

      it { is_expected.to have_http_status :success }
    end

    describe "#show" do
      before { get npq_separation_admin_cohorts_path(cohort) }

      it { is_expected.to have_http_status :success }
    end

    describe "#new" do
      before { get new_npq_separation_admin_cohort_path }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#create" do
      before { post npq_separation_admin_cohorts_path, params: valid_params }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_path(cohort) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#update" do
      before { patch npq_separation_admin_cohort_path(cohort), params: valid_params }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#destroy" do
      before { delete npq_separation_admin_cohort_path(cohort) }

      it_behaves_like "inaccessible to normal admins"
    end
  end

  context "when not logged in" do
    describe "#index" do
      before { get npq_separation_admin_cohorts_path }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#show" do
      before { get npq_separation_admin_cohorts_path(cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#new" do
      before { get new_npq_separation_admin_cohort_path }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before { post npq_separation_admin_cohorts_path, params: valid_params }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_path(cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#update" do
      before { patch npq_separation_admin_cohort_path(cohort), params: valid_params }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#destroy" do
      before { delete npq_separation_admin_cohort_path(cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
