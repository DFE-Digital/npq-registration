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
    it { is_expected.to validate_numericality_of(:page).only_integer.is_greater_than(0).allow_nil }

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

  describe "before_validation" do
    it "nullifies the response bodies when the response comparison is equal" do
      response_comparison = build(:response_comparison, :equal, ecf_response_body: "response", npq_response_body: "response")
      response_comparison.valid?

      expect(response_comparison.ecf_response_body).to be_nil
      expect(response_comparison.npq_response_body).to be_nil
    end

    it "performs a deep sort on JSON response bodies" do
      response_comparison = build(:response_comparison, ecf_response_body: %({ "foo": "bar", "baz": [2, 1] }), npq_response_body: %({ "foo": "baz", "bar": [5, 1, 4] }))
      response_comparison.valid?

      expect(response_comparison.ecf_response_body).to eq(
        <<~JSON.strip,
          {
            "baz": [
              1,
              2
            ],
            "foo": "bar"
          }
        JSON
      )

      expect(response_comparison.npq_response_body).to eq(
        <<~JSON.strip,
          {
            "bar": [
              1,
              4,
              5
            ],
            "foo": "baz"
          }
        JSON
      )
    end

    it "removes excluded attributes" do
      response_comparison = build(:response_comparison, exclude: %w[baz], ecf_response_body: %({ "foo": "bar", "baz": "qux"}), npq_response_body: %({ "foo": "baz", "qux": [{ "baz": ["qux"], "foo": "bar" }] }))
      response_comparison.valid?

      expect(response_comparison.ecf_response_body).to eq(
        <<~JSON.strip,
          {
            "foo": "bar"
          }
        JSON
      )

      expect(response_comparison.npq_response_body).to eq(
        <<~JSON.strip,
          {
            "foo": "baz",
            "qux": [
              {
                "foo": "bar"
              }
            ]
          }
        JSON
      )
    end

    describe "populating response body ids" do
      let(:instance) { build(:response_comparison, :different, ecf_response_body: response_body, npq_response_body: response_body) }

      before { instance.valid? }

      context "when the response body contains multiple results" do
        let(:response_body) { %({ "data": [{ "id": "1" }, { "id": "2" }] }) }

        it { expect(instance.ecf_response_body_ids).to contain_exactly("1", "2") }
        it { expect(instance.npq_response_body_ids).to contain_exactly("1", "2") }
      end

      context "when the response body contains a single result" do
        let(:response_body) { %({ "data": { "id": "1" } }) }

        it { expect(instance.ecf_response_body_ids).to contain_exactly("1") }
        it { expect(instance.npq_response_body_ids).to contain_exactly("1") }
      end

      context "when the response body is not in the expected format" do
        let(:response_body) { %({ "foo": { "id": "1" } }) }

        it { expect(instance.ecf_response_body_ids).to be_empty }
        it { expect(instance.npq_response_body_ids).to be_empty }
      end

      context "when the response body is not JSON" do
        let(:response_body) { %(Error!) }

        it { expect(instance.ecf_response_body_ids).to be_empty }
        it { expect(instance.npq_response_body_ids).to be_empty }
      end

      context "when the response body is nil" do
        let(:response_body) { nil }

        it { expect(instance.ecf_response_body_ids).to be_empty }
        it { expect(instance.npq_response_body_ids).to be_empty }
      end
    end
  end

  describe "scopes" do
    describe ".matching" do
      let(:comparison) { create(:response_comparison, page: 1, lead_provider: matching_comparison.lead_provider) }
      let(:matching_comparison) { create(:response_comparison, page: 2) }

      before do
        # Matches apart from the lead provider
        comparison.dup.update!(lead_provider: create(:lead_provider))

        # Matches apart from the request path
        comparison.dup.update!(request_path: "other/path")

        # Matches apart from the request method
        comparison.dup.update!(request_method: :post)
      end

      subject { described_class.matching(comparison) }

      it { is_expected.to eq([comparison, matching_comparison]) }
    end
  end

  describe ".by_lead_provider" do
    let!(:response_comparison1) { create(:response_comparison, page: 1) }
    let!(:response_comparison2) { create(:response_comparison) }
    let!(:response_comparison3) { create(:response_comparison, lead_provider: response_comparison1.lead_provider, page: 2) }

    subject(:by_lead_provider) { described_class.by_lead_provider }

    it "groups the response comparisons by lead provider name and then description" do
      expect(by_lead_provider).to eq(
        response_comparison1.lead_provider_name => {
          response_comparison1.description => [response_comparison1, response_comparison3],
        },
        response_comparison2.lead_provider_name => {
          response_comparison2.description => [response_comparison2],
        },
      )
    end
  end

  describe "#description" do
    subject { build(:response_comparison, request_method: "get", request_path: "/path").description }

    it { is_expected.to eq("GET /path") }
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

    context "when the response bodies are JSON" do
      let(:instance) { create(:response_comparison, :different, ecf_response_body: %({ "baz": "baz", "foo": "bar" }), npq_response_body: %({ "foo": "bar", "baz": "qux" })) }

      it {
        expect(diff.to_s(:text)).to eq(
          <<~DIFF,
             {
            -  "baz": "baz",
            +  "baz": "qux",
               "foo": "bar"
             }
            \\ No newline at end of file
          DIFF
        )
      }
    end
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

  describe "#unexpected?" do
    subject(:instance) { build(:response_comparison) }

    context "when the status codes are 200" do
      before { instance.assign_attributes(ecf_response_status_code: 200, npq_response_status_code: 200) }

      it { is_expected.not_to be_unexpected }
    end

    context "when neither status code is 200" do
      before { instance.assign_attributes(ecf_response_status_code: 201, npq_response_status_code: 422) }

      it { is_expected.to be_unexpected }
    end

    context "when one status code is not 200" do
      before { instance.assign_attributes(ecf_response_status_code: 200, npq_response_status_code: 422) }

      it { is_expected.to be_unexpected }
    end
  end

  describe "#needs_review?" do
    context "when different" do
      subject(:instance) { build(:response_comparison, :different) }

      it { is_expected.to be_needs_review }
    end

    context "when unexpected" do
      subject(:instance) { build(:response_comparison, :unexpected) }

      it { is_expected.to be_needs_review }
    end

    context "when equal" do
      subject(:instance) { build(:response_comparison, :equal) }

      it { is_expected.not_to be_needs_review }
    end
  end
end
