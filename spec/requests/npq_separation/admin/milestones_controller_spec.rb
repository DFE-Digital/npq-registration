require "rails_helper"

RSpec.describe NpqSeparation::Admin::MilestonesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:schedule) { create(:schedule) }
  let(:cohort) { schedule.cohort }
  let(:milestone) { create(:milestone, schedule:) }
  let(:valid_params)   { { milestone: attributes_for(:milestone) } }

  # only testing code that has not been tested in the feature spec here
  context "when logged in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    context "when a milestone has already been deleted" do
      before do
        milestone_id = milestone.id
        milestone.destroy!
        delete npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone_id), params: { confirm: "1" }
      end

      it { is_expected.to redirect_to npq_separation_admin_cohort_schedule_path(cohort, schedule) }
    end
  end

  context "when logged in as normal admin" do
    before { sign_in_as_admin }

    shared_examples "inaccessible to normal admins" do
      it { is_expected.to redirect_to npq_separation_admin_cohort_schedule_path(cohort, schedule) }

      it "flashes the correct error" do
        expect(flash[:error]).to eq "You must be a super admin to change milestones"
      end
    end

    describe "#new" do
      before { get new_npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#create" do
      before { post npq_separation_admin_cohort_schedule_milestones_path(cohort, schedule), params: valid_params }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#update" do
      before { put npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone), params: valid_params }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#destroy" do
      before { delete npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone) }

      it_behaves_like "inaccessible to normal admins"
    end
  end

  context "when not logged in" do
    describe "#new" do
      before { get new_npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before { post npq_separation_admin_cohort_schedule_milestones_path(cohort, schedule), params: valid_params }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#update" do
      before { put npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone), params: valid_params }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#destroy" do
      before { delete npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone) }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
