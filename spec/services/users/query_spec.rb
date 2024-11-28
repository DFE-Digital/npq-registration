require "rails_helper"

RSpec.describe Users::Query do
  let(:user) { create(:user, :with_get_an_identity_id, email: "user@example.com") }
  let!(:matching_user) { create(:user, :with_get_an_identity_id, email: "match@example.com") }

  describe "#user_with_matching_email" do
    subject { described_class.new(user:).user_with_matching_email }

    before { user.email = "match@example.com" }

    it "returns the matching user" do
      expect(subject).to eq matching_user
    end

    context "when the user passed is the only user that has that email" do
      subject { described_class.new(user: matching_user).user_with_matching_email }

      it "does not return the passed in user" do
        expect(subject).to be_nil
      end
    end
  end
end
