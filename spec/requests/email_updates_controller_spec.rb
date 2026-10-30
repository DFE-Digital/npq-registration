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

      it "sends the confirmation email with the unsubscribe link" do
        do_request
        unsubscribe_key = RegistrationInterest.find_by(email:).unsubscribe_key
        email_sent = ActionMailer::Base.deliveries.last

        expect(email_sent.personalisation[:unsubscribe_link]).to end_with("/email_updates/unsubscribe?unsubscribe_key=#{unsubscribe_key}")
        expect(email_sent.one_click_unsubscribe_url).to eq(email_sent.personalisation[:unsubscribe_link])
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

  describe "#unsubscribe" do
    let!(:registration_interest) { create(:registration_interest) }

    context "with GET" do
      subject { get(unsubscribe_email_updates_path(unsubscribe_key: registration_interest.unsubscribe_key)) && response }

      it { is_expected.to have_http_status :success }

      it "does not unsubscribe" do
        expect { subject }.not_to change(RegistrationInterest, :count)
      end
    end

    context "with POST" do
      subject(:do_request) { post(unsubscribe_email_updates_path(unsubscribe_key:)) && response }

      context "with a registration interest unsubscribe key" do
        let(:unsubscribe_key) { registration_interest.unsubscribe_key }

        it "deletes the registration interest" do
          expect { do_request }.to change(RegistrationInterest, :count).by(-1)
          expect(RegistrationInterest.find_by(id: registration_interest.id)).to be_nil
        end

        it { is_expected.to redirect_to(unsubscribed_email_updates_path) }

        context "without a CSRF token" do
          subject(:do_request) { post(unsubscribe_email_updates_path(unsubscribe_key:)) && response }

          around do |example|
            ActionController::Base.allow_forgery_protection = true
            example.run
          ensure
            ActionController::Base.allow_forgery_protection = false
          end

          it "deletes the registration interest" do
            expect { do_request }.to change(RegistrationInterest, :count).by(-1)
          end
        end
      end

      context "with a user unsubscribe key" do
        let(:user) { create(:user, email_updates_status: :senco, email_updates_unsubscribe_key: SecureRandom.uuid) }
        let(:unsubscribe_key) { user.email_updates_unsubscribe_key }

        it "unsubscribes the user" do
          do_request
          expect(user.reload).to have_attributes(email_updates_status: "empty", email_updates_unsubscribe_key: nil)
        end

        it { is_expected.to redirect_to(unsubscribed_email_updates_path) }
      end

      context "with an unknown unsubscribe key" do
        let(:unsubscribe_key) { SecureRandom.uuid }

        it "does not unsubscribe" do
          expect { do_request }.not_to change(RegistrationInterest, :count)
        end

        it { is_expected.to redirect_to(root_path) }
      end

      context "without an unsubscribe key" do
        let(:unsubscribe_key) { nil }
        let!(:user) { create(:user, email_updates_status: :senco, email_updates_unsubscribe_key: nil) }

        it "does not unsubscribe" do
          expect { do_request }.not_to change(RegistrationInterest, :count)
          expect(user.reload.email_updates_status).to eq("senco")
        end

        it { is_expected.to redirect_to(root_path) }
      end
    end
  end
end
