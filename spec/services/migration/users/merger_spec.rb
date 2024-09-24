require "rails_helper"

RSpec.describe Migration::Users::Merger do
  let(:from_user) { create(:user, uid: SecureRandom.uuid) }
  let(:to_user) { create(:user, uid: SecureRandom.uuid) }

  subject { described_class.new(from_user:, to_user:) }

  describe ".merge" do
    context "when from_user has applications" do
      let!(:application) { create(:application, user: from_user) }

      it "moves applications over to to_user" do
        expect(application.user).to eq(from_user)

        subject.merge!

        expect(application.reload.user).to eq(to_user)
        expect(from_user.uid).to be_nil
      end
    end

    context "when from_user has participant_id_changes" do
      let!(:participant_id_change) { create(:participant_id_change, user: from_user) }

      it "moves participant_id_changes over to to_user" do
        expect(participant_id_change.user).to eq(from_user)

        subject.merge!

        expect(participant_id_change.reload.user).to eq(to_user)
        expect(from_user.uid).to be_nil
      end
    end

    context "when from_user has uid" do
      it "sets from_user.uid to nil" do
        subject.merge!

        expect(from_user.uid).to be_nil
      end
    end
  end
end
