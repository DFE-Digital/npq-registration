require "rails_helper"

RSpec.describe OauthToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "enums" do
    subject(:oauth_token) { build(:oauth_token) }

    it "defines the token_type enum backed by a native enum column" do
      expect(oauth_token).to define_enum_for(:token_type)
        .with_values(refresh_token: "refresh_token")
        .backed_by_column_of_type(:enum)
    end
  end

  describe "scopes" do
    describe ".needs_refresh" do
      subject { described_class.needs_refresh }

      let(:expiring_token) { create(:oauth_token, :stale) }
      let(:recent_token) { create(:oauth_token, :fresh) }

      it { is_expected.to include expiring_token }
      it { is_expected.not_to include recent_token }
    end
  end

  describe "validations" do
    subject { create(:oauth_token) }

    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_presence_of(:token_updated_at) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:token_type) }
  end

  describe "encryption of token" do
    let(:plaintext) { "plaintext-token-abc123" }
    let(:record) { create(:oauth_token, token: plaintext) }

    it "round-trips the plaintext value through the attribute" do
      expect(record.reload.token).to eq(plaintext)
    end

    it "stores the value encrypted at rest" do
      raw = OauthToken.connection.select_value(
        OauthToken.where(id: record.id).select(:token).to_sql,
      )

      expect(raw).not_to include(plaintext)
      expect(raw).to match(/\A\{.*"p":/)
    end
  end

  describe "#store!" do
    subject(:reloaded) { token.reload }

    before do
      freeze_time
      token.store!("some-token")
    end

    let(:user) { create :user }

    context "with new token" do
      let(:token) { OauthToken.new(user:) }

      it { is_expected.to be_persisted }
      it { is_expected.to have_attributes changes: be_empty }

      it "saves correct attributes" do
        expect(reloaded).to have_attributes token: "some-token",
                                            token_updated_at: Time.current,
                                            token_type: "refresh_token"
      end
    end

    context "with existing token" do
      let :token do
        OauthToken.create!(user:, token: "old", token_updated_at: 20.minutes.ago)
      end

      it { is_expected.to be_persisted }
      it { is_expected.to have_attributes changes: be_empty }

      it "saves correct attributes" do
        expect(reloaded).to have_attributes token: "some-token",
                                            token_updated_at: Time.current,
                                            token_type: "refresh_token"
      end
    end
  end
end
