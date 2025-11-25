require "rails_helper"

RSpec.describe NpqSeparation::Admin::MilestonesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:schedule) { create(:schedule) }
  let(:cohort) { schedule.cohort }
  let(:milestone) { create(:milestone, schedule:) }
  let(:params) { { milestone: attributes_for(:milestone) } }

  # only testing code that has not been tested in the feature spec here
  context "when logged in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    describe "#new" do
      context "when the schedule has limited declaration types available" do
        let(:schedule) { create(:schedule, allowed_declaration_types: %w[started retained-1]) }

        before { get new_npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule) }

        it "only shows the available declaration types" do
          expect(response.body).to include("started")
          expect(response.body).to include("retained-1")
          expect(response.body).not_to include("retained-2")
          expect(response.body).not_to include("completed")
        end
      end
    end

    describe "#create" do
      context "when no declaration type is chosen" do
        let(:params) { { milestone: attributes_for(:milestone).except(:declaration_type) } }

        before { post npq_separation_admin_cohort_schedule_milestones_path(cohort, schedule), params: }

        it { is_expected.to have_http_status :unprocessable_entity }
      end
    end

    describe "#update" do
      context "when no statement date is chosen" do
        let(:params) { { milestones_update: { statement_date: "" } } }

        before { put npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone), params: }

        it { is_expected.to have_http_status :unprocessable_entity }
      end
    end

    describe "#destroy" do
      context "when a milestone has already been deleted" do
        before do
          milestone_id = milestone.id
          milestone.destroy!
          delete npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone_id), params: { confirm: "1" }
        end

        it { is_expected.to redirect_to npq_separation_admin_cohort_schedule_path(cohort, schedule) }
      end
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
      before { post npq_separation_admin_cohort_schedule_milestones_path(cohort, schedule), params: }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#update" do
      before { put npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone), params: }

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
      before { post npq_separation_admin_cohort_schedule_milestones_path(cohort, schedule), params: }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#update" do
      before { put npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone), params: }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#destroy" do
      before { delete npq_separation_admin_cohort_schedule_milestone_path(cohort, schedule, milestone) }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
