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
end
