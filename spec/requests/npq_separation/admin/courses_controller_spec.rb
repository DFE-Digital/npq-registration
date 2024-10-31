require "rails_helper"

RSpec.describe NpqSeparation::Admin::CoursesController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "/npq_separation/admin/courses" do
    subject do
      get npq_separation_admin_courses_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "/npq_separation/admin/courses/{id}" do
    let(:course_id) { create(:course).id }

    subject do
      get npq_separation_admin_course_path(course_id)
      response
    end

    it { is_expected.to have_http_status(:ok) }

    context "when the course cannot be found", :exceptions_app do
      let(:course_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
