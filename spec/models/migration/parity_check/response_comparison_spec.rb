require "rails_helper"

RSpec.describe Migration::ParityCheck::ResponseComparison, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:name).to(:lead_provider).with_prefix }
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

      it { is_expected.not_to validate_presence_of(:ecf_response_body) }
      it { is_expected.not_to validate_presence_of(:npq_response_body) }
    end

    context "when the response comparison is different" do
      subject { create(:response_comparison, :different) }

      it { is_expected.to validate_presence_of(:ecf_response_body) }
      it { is_expected.to validate_presence_of(:npq_response_body) }
    end
  end

  describe "scopes" do
    describe ".with_differences" do
      let!(:different_status_code) { create(:response_comparison, ecf_response_status_code: 200, npq_response_status_code: 201, ecf_response_body: "test", npq_response_body: "test") }
      let!(:different_response_body) { create(:response_comparison, ecf_response_body: "ecf", npq_response_body: "npq", ecf_response_status_code: 200, npq_response_status_code: 200) }

      before { create(:response_comparison, :equal) }

      subject { described_class.with_differences }

      it { is_expected.to contain_exactly(different_status_code, different_response_body) }
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

  describe ".by_lead_provider" do
    let!(:response_comparison1) { create(:response_comparison) }
    let!(:response_comparison2) { create(:response_comparison) }
    let!(:response_comparison3) { create(:response_comparison, lead_provider: response_comparison1.lead_provider) }

    subject(:by_lead_provider) { described_class.by_lead_provider }

    it "groups the response comparisons by lead provider name" do
      expect(by_lead_provider).to eq(
        response_comparison1.lead_provider_name => [response_comparison1, response_comparison3],
        response_comparison2.lead_provider_name => [response_comparison2],
      )
    end
  end

  describe "#description" do
    subject { build(:response_comparison, request_method: "get", request_path: "/path").description }

    it { is_expected.to eq("GET /path") }
  end

  describe "#npq_slower?" do
    subject(:instance) { create(:response_comparison) }

    context "when NPQ has a slower response time than ECF" do
      before { instance.npq_response_time_ms = instance.ecf_response_time_ms + 1 }

      it { is_expected.to be_npq_slower }
    end

    context "when NPQ has a faster response time than ECF" do
      before { instance.npq_response_time_ms = instance.ecf_response_time_ms - 1 }

      it { is_expected.not_to be_npq_slower }
    end

    context "when NPQ has tje same response time as ECF" do
      before { instance.npq_response_time_ms = instance.ecf_response_time_ms }

      it { is_expected.not_to be_npq_slower }
    end
  end

  describe "#response_body_diff" do
    let(:instance) { create(:response_comparison, :different) }

    subject(:diff) { instance.response_body_diff }

    it { is_expected.to be_a(Diffy::Diff) }

    it {
      expect(diff.to_s(:text)).to eq(
        <<~DIFF,
          -response1
          \\ No newline at end of file
          +response2
          \\ No newline at end of file
        DIFF
      )
    }
  end

  describe "#response_times_by_path" do
    before do
      create(:response_comparison, request_path: "/path1", ecf_response_time_ms: 100, npq_response_time_ms: 200)
      create(:response_comparison, request_path: "/path1", ecf_response_time_ms: 200, npq_response_time_ms: 200)
      create(:response_comparison, request_path: "/path2", ecf_response_time_ms: 50, npq_response_time_ms: 100)
    end

    subject(:result) { described_class.response_times_by_path }

    it "returns the response times grouped by request path" do
      expect(result).to eq({
        "GET /path1" => {
          ecf: {
            avg: 150,
            min: 100,
            max: 200,
          },
          npq: {
            avg: 200,
            min: 200,
            max: 200,
          },
        },
        "GET /path2" => {
          ecf: {
            avg: 50,
            min: 50,
            max: 50,
          },
          npq: {
            avg: 100,
            min: 100,
            max: 100,
          },
        },
      })
    end
  end

  describe "#different?" do
    subject(:instance) { build(:response_comparison) }

    context "when the status codes and response bodies are equal" do
      before { instance.assign_attributes(ecf_response_status_code: 200, npq_response_status_code: 200, ecf_response_body: "response", npq_response_body: "response") }

      it { is_expected.not_to be_different }
    end

    context "when the status codes are equal and the response bodies are both nil" do
      before { instance.assign_attributes(ecf_response_status_code: 200, npq_response_status_code: 200, ecf_response_body: nil, npq_response_body: nil) }

      it { is_expected.not_to be_different }
    end

    context "when the status codes are equal but the response bodies are different" do
      before { instance.assign_attributes(ecf_response_status_code: 200, npq_response_status_code: 200, ecf_response_body: "response1", npq_response_body: "response2") }

      it { is_expected.to be_different }
    end

    context "when the response bodies are equal but the status codes are different" do
      before { instance.assign_attributes(ecf_response_status_code: 201, npq_response_status_code: 202, ecf_response_body: "response", npq_response_body: "response") }

      it { is_expected.to be_different }
    end
  end
end
