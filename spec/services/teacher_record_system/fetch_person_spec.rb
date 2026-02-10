require "rails_helper"

RSpec.describe TeacherRecordSystem::FetchPerson do
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

  let(:person_service) { TeacherRecordSystem::V3::Person }

  describe ".fetch" do
    context "when OAuth endpoint succeeds" do
      before do
        allow(person_service).to receive(:find_with_token).and_return(teaching_record)
      end

      it "returns result with teaching record data" do
        result = described_class.fetch(access_token:)

        expect(result.full_name).to eq("Sarah Jane Smith")
        expect(result.previous_names).to eq(["Sarah Johnson"])
      end

      it "populates the teaching_record field with API data" do
        result = described_class.fetch(access_token:)

        expect(result.teaching_record).to eq(teaching_record)
      end
    end

    context "when OAuth endpoint returns nil" do
      before do
        allow(person_service).to receive(:find_with_token).and_return(nil)
      end

      it "raises ApiError" do
        expect { described_class.fetch(access_token:) }.to raise_error(TeacherRecordSystem::ApiError, "Teaching record not found")
      end
    end

    context "when timeout occurs" do
      before do
        allow(person_service).to receive(:find_with_token).and_raise(TeacherRecordSystem::TimeoutError)
      end

      it "raises TimeoutError" do
        expect { described_class.fetch(access_token:) }.to raise_error(TeacherRecordSystem::TimeoutError)
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(person_service).to receive(:find_with_token).and_raise(StandardError, "Unexpected error")
      end

      it "allows the error to propagate" do
        expect { described_class.fetch(access_token:) }.to raise_error(StandardError, "Unexpected error")
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
        result = described_class.fetch(access_token:)

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
        result = described_class.fetch(access_token:)

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
        result = described_class.fetch(access_token:)

        expect(result.previous_names).to eq([
          "Sarah Johnson",
          "Sarah Ann Williams",
        ])
      end
    end
  end
end
