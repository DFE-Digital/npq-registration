require "rails_helper"

RSpec.describe Admin::CoursesController, type: :request do
  include Helpers::RequestAdminLogin

  before { sign_in_as_admin }

  describe "/admin/courses" do
    subject do
      get admin_courses_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "/admin/courses/{id}" do
    let(:course_id) { create(:course).id }

    subject do
      get admin_course_path(course_id)
      response
    end

    it { is_expected.to have_http_status(:ok) }

    context "when the course cannot be found", :exceptions_app do
      let(:course_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
