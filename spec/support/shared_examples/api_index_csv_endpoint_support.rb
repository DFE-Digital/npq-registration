# frozen_string_literal: true

RSpec.shared_examples "an API index Csv endpoint" do
  context "when authorized" do
    context "when 2 resources exist for current_lead_provider" do
      let!(:resource1) { create_resource(lead_provider: current_lead_provider) }
      let!(:resource2) { create_resource(lead_provider: current_lead_provider) }

      before do
        create_resource(lead_provider: create(:lead_provider, name: "Another lead provider"))
      end

      it "returns a header row and 2 resources" do
        api_get(path)

        expect(response.status).to eq(200)
        expect(response.content_type).to eql("text/csv")
        expect(parsed_csv_response.count).to eq(3)
      end

      it "calls the correct query/serializer" do
        allow(serializer).to receive(:new).with([resource1, resource2]).and_return(mock_serializer)
        expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider)).and_call_original

        api_get(path)

        expect(mock_serializer).to have_received(:serialize)
      end
    end

    context "when no resources exist" do
      it "returns only the headers in csv" do
        api_get(path)

        expect(response.status).to eq 200
        expect(parsed_csv_response.count).to eq(1)
        expect(parsed_csv_response.first).to eq(serializer::CSV_HEADERS)
      end
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

RSpec.shared_examples "an API index Csv endpoint with filter by cohort" do
  context "when fitlering by cohort" do
    let(:cohort_2023) { create(:cohort, start_year: 2023) }
    let(:cohort_2024) { create(:cohort, start_year: 2024) }
    let(:cohort_2025) { create(:cohort, start_year: 2025) }

    it "returns resources for the specified cohorts" do
      create_resource(lead_provider: current_lead_provider, cohort: cohort_2023)
      create_resource(lead_provider: current_lead_provider, cohort: cohort_2024)
      create_resource(lead_provider: current_lead_provider, cohort: cohort_2025)

      api_get(path, params: { filter: { cohort: "2023,2024" } })

      expect(parsed_csv_response.size).to eq(3)
    end

    it "calls the correct query" do
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, cohort_start_years: "2023,2024")).and_call_original

      api_get(path, params: { filter: { cohort: "2023,2024" } })
    end
  end
end

RSpec.shared_examples "an API index Csv endpoint with filter by updated_since" do
  context "when fitlering by updated_since" do
    it "returns resources updated since the specified date" do
      create_resource(lead_provider: current_lead_provider, updated_at: 2.hours.ago)
      create_resource(lead_provider: current_lead_provider, updated_at: 1.minute.ago)

      api_get(path, params: { filter: { updated_since: 1.hour.ago.iso8601 } })

      expect(parsed_csv_response.size).to eq(2)
    end

    it "calls the correct query" do
      updated_since = 1.hour.ago.iso8601
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, updated_since: Time.iso8601(updated_since))).and_call_original

      api_get(path, params: { filter: { updated_since: } })
    end

    it "returns 400 - bad request for invalid updated_since" do
      api_get(path, params: { filter: { updated_since: "invalid" } })

      expect(response.status).to eq 400
      expect(parsed_response["errors"]).to eq([
        {
          "detail" => "The filter '#/updated_since' must be a valid ISO 8601 date",
          "title" => "Bad request",
        },
      ])
    end
  end
end
