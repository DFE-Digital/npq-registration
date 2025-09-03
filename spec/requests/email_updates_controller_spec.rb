require "rails_helper"

RSpec.describe EmailUpdatesController, type: :request do
  let(:user) { create :user }

  describe "#new" do
    subject { get(new_email_update_path) && response }

    context "when logged in" do
      before { allow(User).to receive(:find_by).and_return user }

      it { is_expected.to have_http_status :success }
    end

    context "when not logged in" do
      it { is_expected.to redirect_to root_path }
    end
  end

  describe "#create" do
    subject(:do_request) { post(email_updates_path, params:) && response }

    let(:params) { { email_updates: { email_updates_status: :senco } } }

    context "when logged in" do
      before { allow(User).to receive(:find_by).and_return user }

      context "with valid request" do
        it "saves email update" do
          expect {
            do_request
          }.to change(user, :email_updates_status).to("senco")

          expect(do_request).to have_http_status(:success)
        end
      end

      context "with invalid request" do
        let(:params) { {} }

        it "does not save email update" do
          expect { do_request }.not_to change(user, :email_updates_status)

          expect(do_request).to have_http_status(:success)
        end
      end
    end

    context "when not logged in" do
      it { is_expected.to redirect_to root_path }
    end
  end
end
