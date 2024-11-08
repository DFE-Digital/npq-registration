require "rails_helper"

RSpec.describe "Qualifications endpoint", type: :request do
  describe "GET /api/teacher-record-service/npq-qualifications/:trn" do
    let(:path) { "/api/teacher-record-service/npq-qualifications/#{trn}" }

    context "when the TRN exists" do
      let!(:participant_outcome) { create(:participant_outcome, :passed) }
      let(:trn) { User.last.trn }

      context "when authorized" do
        it "returns the qualifications" do
          api_get(path)

          expect(response.status).to eq 200
          expect(response.content_type).to eql("application/json")
          expect(parsed_response["data"]["trn"]).to eq(trn)
          expect(parsed_response["data"]["qualifications"].first["award_date"]).to eq(participant_outcome.completion_date.to_fs(:db))
          expect(parsed_response["data"]["qualifications"].first["npq_type"]).to eq(participant_outcome.course.short_code)
        end
      end

      context "when unauthorized" do
        it "returns 401 - unauthorized" do
          api_get(path, token: "incorrect-token")

          expect(response.status).to eq 401
          expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
          expect(response.content_type).to eql("application/json")
        end
      end
    end

    context "when the TRN does not exist" do
      let(:trn) { "0000000" }

      it "returns an empty array" do
        api_get(path)

        expect(parsed_response["data"]["qualifications"]).to be_empty
      end
    end
  end
end
