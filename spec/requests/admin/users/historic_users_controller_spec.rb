require "rails_helper"

RSpec.describe Admin::Users::HistoricUsersController, type: :request do
  include Helpers::RequestAdminLogin

  describe "/admin/users/historic/{trn}" do
    subject do
      get admin_historic_user_path("1234567")
      response
    end

    context "when signed in as an admin" do
      before { sign_in_as_admin }

      context "when there are legacy outcomes for the TRN" do
        before { create(:legacy_passed_participant_outcome, trn: "1234567") }

        it { is_expected.to have_http_status(:ok) }
      end

      context "when there are no legacy outcomes for the TRN", :exceptions_app do
        it { is_expected.to have_http_status(:not_found) }
      end
    end

    context "when signed in as a teacher" do
      let(:teacher) { create(:user, :with_teacher_auth, trn: "1234567") }

      before do
        create(:legacy_passed_participant_outcome, trn: "1234567")

        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:teacher_auth] = create(:omniauth_auth_hash)
        allow(User).to receive(:find_or_create_from_teacher_auth).and_return(teacher)
        post "/users/auth/teacher_auth/callback"
      end

      after do
        OmniAuth.config.mock_auth.delete(:teacher_auth)
        OmniAuth.config.test_mode = false
      end

      it "is signed in as the teacher" do
        expect(session[:user_id]).to eq(teacher.id)
      end

      it { is_expected.to redirect_to(sign_in_path) }
    end

    context "when not signed in" do
      before { create(:legacy_passed_participant_outcome, trn: "1234567") }

      it { is_expected.to redirect_to(sign_in_path) }
    end
  end
end
