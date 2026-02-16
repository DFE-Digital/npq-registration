require "rails_helper"

RSpec.describe TeacherRecordService::RecordRetrieval do
  let(:access_token) { "test-token" }
  let(:trn) { "1234567" }
  let(:teaching_record) do
    {
      "trn" => trn,
      "firstName" => "Sarah",
      "middleName" => "Jane",
      "lastName" => "Smith",
      "previousNames" => [
        { "firstName" => "Sarah", "lastName" => "Johnson" },
      ],
    }
  end

  let(:person_service) { TeacherRecordService::V3::Person }

  subject { described_class.new(access_token:) }

  describe "#call" do
    context "when OAuth endpoint succeeds" do
      before do
        allow(person_service).to receive(:find_with_token).and_return(teaching_record)
      end

      it "returns successful result with teaching record" do
        result = subject.call

        expect(result.success?).to be(true)
        expect(result.full_name).to eq("Sarah Jane Smith")
        expect(result.previous_names).to eq(["Sarah Johnson"])
        expect(result.error_type).to be_nil
      end

      it "populates the teaching_record field with API data" do
        result = subject.call

        expect(result.teaching_record).to eq(teaching_record)
      end
    end

    context "when OAuth endpoint returns nil" do
      before do
        allow(person_service).to receive(:find_with_token).and_return(nil)
      end

      it "returns failure result" do
        result = subject.call

        expect(result.success?).to be(false)
        expect(result.error_type).to eq(:api_error)
      end
    end

    context "when timeout occurs" do
      before do
        call_count = 0
        allow(person_service).to receive(:find_with_token) do
          call_count += 1
          raise Timeout::Error if call_count <= 2

          teaching_record
        end
      end

      it "retries once then returns failure" do
        result = subject.call

        expect(result.success?).to be(false)
        expect(result.error_type).to eq(:timeout)
        expect(person_service).to have_received(:find_with_token).twice
      end
    end

    context "when timeout occurs once then succeeds" do
      before do
        call_count = 0
        allow(person_service).to receive(:find_with_token) do
          call_count += 1
          raise Timeout::Error if call_count == 1

          teaching_record
        end
      end

      it "retries and returns successful result" do
        result = subject.call

        expect(result.success?).to be(true)
        expect(result.full_name).to eq("Sarah Jane Smith")
        expect(person_service).to have_received(:find_with_token).twice
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(person_service).to receive(:find_with_token).and_raise(StandardError, "Unexpected error")
      end

      it "returns failure result with unknown_error type" do
        result = subject.call

        expect(result.success?).to be(false)
        expect(result.error_type).to eq(:unknown_error)
      end
    end

    context "when building full name with no middle name" do
      let(:teaching_record) do
        {
          "firstName" => "John",
          "lastName" => "Doe",
        }
      end

      before do
        allow(person_service).to receive(:find_with_token).and_return(teaching_record)
      end

      it "formats name correctly without middle name" do
        result = subject.call

        expect(result.full_name).to eq("John Doe")
      end
    end

    context "when teaching record has no previous names" do
      let(:teaching_record) do
        {
          "firstName" => "John",
          "lastName" => "Doe",
        }
      end

      before do
        allow(person_service).to receive(:find_with_token).and_return(teaching_record)
      end

      it "returns empty array for previous names" do
        result = subject.call

        expect(result.previous_names).to eq([])
      end
    end

    context "when teaching record has multiple previous names" do
      let(:teaching_record) do
        {
          "firstName" => "Sarah",
          "lastName" => "Smith",
          "previousNames" => [
            { "firstName" => "Sarah", "lastName" => "Johnson" },
            { "firstName" => "Sarah", "middleName" => "Ann", "lastName" => "Williams" },
          ],
        }
      end

      before do
        allow(person_service).to receive(:find_with_token).and_return(teaching_record)
      end

      it "formats all previous names correctly" do
        result = subject.call

        expect(result.previous_names).to eq([
          "Sarah Johnson",
          "Sarah Ann Williams",
        ])
      end
    end
  end
end
