require "rails_helper"

RSpec.describe User do
  describe "relationships" do
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:ecf_sync_request_logs).dependent(:destroy) }
  end

  describe "methods" do
    it { expect(User.new).to be_actual_user }
    it { expect(User.new).not_to be_null_user }
  end

  describe "#update_email_updates_status" do
    let(:user) { create(:user) }
    let(:form) { EmailUpdates.new(email_updates_status: :senco) }
    let(:uuid) { "123" }

    before do
      allow(SecureRandom).to receive(:uuid) { uuid }
    end

    context "when value is correct" do
      it "saves the value" do
        expect {
          user.update_email_updates_status(form)
        }.to change { user.reload.email_updates_status }.from("empty").to("senco")
      end

      it "creates proper unsubscribe key" do
        expect {
          user.update_email_updates_status(form)
        }.to change { user.reload.email_updates_unsubscribe_key }.from(nil).to(uuid)
      end
    end

    context "when value is changed" do
      let(:user) { create(:user, email_updates_unsubscribe_key: "432") }

      it "does not changes unsubscribe key" do
        expect {
          user.update_email_updates_status(form)
        }.not_to(change { user.reload.email_updates_unsubscribe_key })
      end
    end
  end

  describe "#unsubscribe_from_email_updates" do
    let(:user) { create(:user, email_updates_unsubscribe_key: "432", email_updates_status: "senco") }

    it "saves the value" do
      expect {
        user.unsubscribe_from_email_updates
      }.to change { user.reload.email_updates_status }.from("senco").to("empty")
    end

    it "creates proper unsubscribe key" do
      expect {
        user.unsubscribe_from_email_updates
      }.to change { user.reload.email_updates_unsubscribe_key }.from("432").to(nil)
    end
  end
end
