require "rails_helper"

RSpec.describe EmailUpdatesController, type: :request do
  describe "#new" do
    subject { get(new_email_update_path) && response }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    subject(:do_request) { post(email_updates_path, params:) && response }

    let(:email) { "user@example.com" }
    let(:params) { { email_updates: { email:, course: "npq-senco" } } }

    context "with valid request" do
      it "creates a registration interest" do
        do_request
        expect(RegistrationInterest.find_by(email:)).to have_attributes(
          email:,
          course: "npq-senco",
        )

        expect(do_request).to have_http_status(:success)
      end
    end

    context "with missing email" do
      let(:params) { { email_updates: { course: "npq-senco" } } }

      it "does not save email update" do
        expect { do_request }.not_to change(RegistrationInterest, :count)

        expect(do_request).to have_http_status(:unprocessable_content)
      end
    end

    context "with missing course" do
      let(:params) { { email_updates: { email: } } }

      it "does not save email update" do
        expect { do_request }.not_to change(RegistrationInterest, :count)

        expect(do_request).to have_http_status(:unprocessable_content)
      end
    end
  end
end
