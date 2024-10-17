require "rails_helper"

RSpec.describe Migration::ParityCheck::ResponseComparison, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:request_path) }
    it { is_expected.to validate_inclusion_of(:request_method).in_array(%w[get post put]) }
    it { is_expected.to validate_inclusion_of(:ecf_response_status_code).in_range(100..599) }
    it { is_expected.to validate_inclusion_of(:npq_response_status_code).in_range(100..599) }
    it { is_expected.to validate_numericality_of(:ecf_response_time_ms).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:npq_response_time_ms).is_greater_than(0) }

    context "when the response comparison is equal" do
      subject { create(:response_comparison, :equal) }

      it { is_expected.to validate_presence_of(:ecf_response_body) }
      it { is_expected.to validate_presence_of(:npq_response_body) }
    end

    context "when the response comparison is different" do
      subject { create(:response_comparison, :different) }

      it { is_expected.to validate_presence_of(:ecf_response_body) }
      it { is_expected.to validate_presence_of(:npq_response_body) }
    end
  end

  describe "before_validation" do
    it "nullifies the response bodies when the response comparison is equal" do
      response_comparison = build(:response_comparison, :equal, ecf_response_body: "response", npq_response_body: "response")
      response_comparison.valid?

      expect(response_comparison.ecf_response_body).to be_nil
      expect(response_comparison.npq_response_body).to be_nil
    end
  end

  describe "#equal?, #different?" do
    subject(:instance) { build(:response_comparison) }

    context "when the status codes and response bodies are equal" do
      before { instance.assign_attributes(ecf_response_status_code: 200, npq_response_status_code: 200, ecf_response_body: "response", npq_response_body: "response") }

      it { is_expected.to be_equal }
      it { is_expected.not_to be_different }
    end

    context "when the status codes are equal and the response bodies are both nil" do
      before { instance.assign_attributes(ecf_response_status_code: 200, npq_response_status_code: 200, ecf_response_body: nil, npq_response_body: nil) }

      it { is_expected.to be_equal }
      it { is_expected.not_to be_different }
    end

    context "when the status codes are equal but the response bodies are different" do
      before { instance.assign_attributes(ecf_response_status_code: 200, npq_response_status_code: 200, ecf_response_body: "response1", npq_response_body: "response2") }

      it { is_expected.to be_different }
      it { is_expected.not_to be_equal }
    end

    context "when the response bodies are equal but the status codes are different" do
      before { instance.assign_attributes(ecf_response_status_code: 201, npq_response_status_code: 202, ecf_response_body: "response", npq_response_body: "response") }

      it { is_expected.to be_different }
      it { is_expected.not_to be_equal }
    end
  end
end
