require "rails_helper"

RSpec.describe ApiToken, type: :model do
  let(:lead_provider) { create(:lead_provider) }
  let(:unhashed_token) { "XXX123" }

  describe "associations" do
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:hashed_token) }
  end

  describe ".create_with_random_token!" do
    it "generates a random hashed token that can be used" do
      unhashed_token = described_class.create_with_random_token!(lead_provider:)

      expect(
        described_class.find_by_unhashed_token(unhashed_token),
      ).to eql(described_class.order(:created_at).last)
    end
  end

  describe ".find_by_unhashed_token" do
    let!(:api_token) { described_class.create_with_known_token!(unhashed_token, lead_provider:) }

    it "able to find with unhashed token" do
      at = described_class.find_by_unhashed_token(unhashed_token)
      expect(at).to eql(api_token)
      expect(at.lead_provider).to eql(lead_provider)
    end
  end

  describe ".create_with_known_token!" do
    it "creates api token with correct unhashed_token" do
      described_class.create_with_known_token!(unhashed_token, lead_provider:)
      hashed_token = Devise.token_generator.digest(described_class, :hashed_token, unhashed_token)

      at = described_class.first
      expect(at.lead_provider).to eql(lead_provider)
      expect(at.hashed_token).to eql(hashed_token)
    end
  end
end
