require "rails_helper"

RSpec.describe NpqSeparation::Admin::SchedulesController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:schedule)       { create(:schedule) }
  let(:cohort)         { schedule.cohort }
  let(:valid_params)   { { schedule: attributes_for(:schedule).merge(course_group_id: course_group.id) } }
  let(:invalid_params) { { schedule: { name: "" } } }
  let(:course_group)   { create(:course_group) }

  context "when logged in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    describe "#show" do
      before { get npq_separation_admin_cohort_schedule_path(cohort, schedule) }

      it { is_expected.to have_http_status :success }
    end

    describe "#new" do
      before { get new_npq_separation_admin_cohort_schedule_path(cohort) }

      it { is_expected.to have_http_status :success }
    end

    describe "#create" do
      before { post npq_separation_admin_cohort_schedules_path(cohort), params: valid_params }

      it { is_expected.to redirect_to npq_separation_admin_cohort_path(cohort) }

      it "flashes success" do
        expect(flash[:success]).to match(/Schedule created/i)
      end
    end

    describe "#create with invalid params" do
      before { post npq_separation_admin_cohort_schedules_path(cohort), params: invalid_params }

      it { is_expected.to have_http_status :unprocessable_entity }
    end

    context "with editable cohort" do
      before { allow_any_instance_of(Cohort).to receive(:editable?).and_return(true) }

      describe "#edit" do
        before { get edit_npq_separation_admin_cohort_schedule_path(cohort, schedule) }

        it { is_expected.to have_http_status :success }
      end

      describe "#update" do
        before { patch npq_separation_admin_cohort_schedule_path(cohort, schedule), params: valid_params }

        it { is_expected.to redirect_to npq_separation_admin_cohort_path(cohort) }

        it "flashes success" do
          expect(flash[:success]).to match(/Schedule updated/i)
        end
      end

      describe "#update with invalid params" do
        before { patch npq_separation_admin_cohort_schedule_path(cohort, schedule), params: invalid_params }

        it { is_expected.to have_http_status :unprocessable_entity }
      end

      describe "#destroy" do
        before { delete npq_separation_admin_cohort_schedule_path(cohort, schedule) }

        it { is_expected.to have_http_status :success }
      end

      describe "#destroy with confirm" do
        before { delete npq_separation_admin_cohort_schedule_path(cohort, schedule), params: { confirm: "1" } }

        it { is_expected.to redirect_to npq_separation_admin_cohort_path(cohort) }

        it "flashes success" do
          expect(flash[:success]).to match(/Schedule deleted/i)
        end
      end
    end

    context "with non-editable cohort" do
      before { allow_any_instance_of(Cohort).to receive(:editable?).and_return(false) }

      shared_examples "cannot be changed" do
        it { is_expected.to redirect_to npq_separation_admin_cohort_schedule_path(cohort, schedule) }

        it "flashes the correct error" do
          expect(flash[:error]).to match(/This schedule is not editable/i)
        end
      end

      describe "#edit" do
        before { get edit_npq_separation_admin_cohort_schedule_path(cohort, schedule) }

        it_behaves_like "cannot be changed"
      end

      describe "#update" do
        before { patch npq_separation_admin_cohort_schedule_path(cohort, schedule), params: valid_params }

        it_behaves_like "cannot be changed"
      end

      describe "#destroy" do
        before { delete npq_separation_admin_cohort_schedule_path(cohort, schedule) }

        it_behaves_like "cannot be changed"
      end

      describe "#destroy with confirm" do
        before { delete npq_separation_admin_cohort_schedule_path(cohort, schedule), params: { confirm: "1" } }

        it_behaves_like "cannot be changed"
      end
    end
  end

  context "when logged in as normal admin" do
    before { sign_in_as_admin }

    shared_examples "inaccessible to normal admins" do
      it { is_expected.to redirect_to npq_separation_admin_cohort_path(cohort) }

      it "flashes the correct error" do
        expect(flash[:error]).to match(/You must be a super admin to change schedules/i)
      end
    end

    describe "#show" do
      before { get npq_separation_admin_cohort_schedule_path(cohort, schedule) }

      it { is_expected.to have_http_status :success }
    end

    describe "#new" do
      before { get new_npq_separation_admin_cohort_schedule_path(cohort) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#create" do
      before { post npq_separation_admin_cohort_schedules_path(cohort), params: valid_params }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_schedule_path(cohort, schedule) }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#update" do
      before { patch npq_separation_admin_cohort_schedule_path(cohort, schedule), params: valid_params }

      it_behaves_like "inaccessible to normal admins"
    end

    describe "#destroy" do
      before { delete npq_separation_admin_cohort_schedule_path(cohort, schedule) }

      it_behaves_like "inaccessible to normal admins"
    end
  end

  context "when not logged in" do
    describe "#show" do
      before { get npq_separation_admin_cohort_schedule_path(cohort, schedule) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#new" do
      before { get new_npq_separation_admin_cohort_schedule_path(cohort) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before { post npq_separation_admin_cohort_schedules_path(cohort), params: valid_params }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#edit" do
      before { get edit_npq_separation_admin_cohort_schedule_path(cohort, schedule) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#update" do
      before { patch npq_separation_admin_cohort_schedule_path(cohort, schedule), params: valid_params }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#destroy" do
      before { delete npq_separation_admin_cohort_schedule_path(cohort, schedule) }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
