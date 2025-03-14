require "rails_helper"

RSpec.describe APIToken, type: :model do
  let(:lead_provider) { create(:lead_provider) }
  let(:unhashed_token) { "XXX123" }
  let(:scope) { "lead_provider" }

  describe "associations" do
    it { is_expected.to belong_to(:lead_provider).without_validating_presence }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:hashed_token) }
    it { is_expected.to validate_presence_of(:scope) }
    it { is_expected.to define_enum_for(:scope).with_values(lead_provider: "lead_provider", teacher_record_service: "teacher_record_service").backed_by_column_of_type(:enum) }
  end

  describe ".create_with_random_token!" do
    it "creates an APIToken using a random hashed token" do
      unhashed_token = APIToken.create_with_random_token!(lead_provider:, scope:)

      expect(
        APIToken.find_by_unhashed_token(unhashed_token, scope:),
      ).to eql(APIToken.order(:created_at, :id).last)
    end

    context "when a lead provider is not specified" do
      it "does not create an APIToken without a lead provider" do
        expect { APIToken.create_with_random_token!(scope:) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when the scope is teacher_record_service" do
      let(:scope) { "teacher_record_service" }

      context "when a lead provider is not specified" do
        it "creates an APIToken without a lead provider" do
          expect(APIToken.create_with_random_token!(scope:)).to be_present
        end
      end
    end
  end

  describe ".find_by_unhashed_token" do
    it "finds an APIToken using an unhashed token" do
      api_token = APIToken.create_with_known_token!(unhashed_token, lead_provider:, scope:)
      at = APIToken.find_by_unhashed_token(unhashed_token, scope:)
      expect(at).to eql(api_token)
      expect(at.lead_provider).to eql(lead_provider)
    end

    context "when token is in another scope" do
      before { APIToken.create_with_known_token!(unhashed_token, scope: "teacher_record_service") }

      it "doesn't find the APIToken" do
        expect(APIToken.find_by_unhashed_token(unhashed_token, scope:)).to be_nil
      end
    end
  end

  describe ".create_with_known_token!" do
    it "creates an APIToken with using an unhashed token" do
      APIToken.create_with_known_token!(unhashed_token, lead_provider:)
      hashed_token = Devise.token_generator.digest(APIToken, :hashed_token, unhashed_token)

      at = APIToken.first
      expect(at.lead_provider).to eql(lead_provider)
      expect(at.hashed_token).to eql(hashed_token)
    end
  end
end
