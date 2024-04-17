require "rails_helper"

RSpec.describe "Statements endpoint", type: "request" do
  let(:current_lead_provider) { create(:lead_provider) }

  describe "GET /api/v3/statements" do
    context "when authorized" do
      context "when 2 statements exist for current_lead_provider" do
        let!(:statement1) { create(:statement, lead_provider: current_lead_provider) }
        let!(:statement2) { create(:statement, lead_provider: current_lead_provider) }

        before do
          create(:statement, lead_provider: create(:lead_provider, name: "Another lead provider"))
        end

        it "returns 2 statements" do
          api_get("/api/v3/statements")

          expect(response.status).to eq 200
          expect(response.content_type).to eql("application/json")
          expect(parsed_response["data"].size).to eq(2)
          expect(response_ids).to match_array([statement1.ecf_id, statement2.ecf_id])
        end
      end

      context "when no statements exist" do
        it "returns empty" do
          api_get("/api/v3/statements")

          expect(response.status).to eq 200
          expect(parsed_response["data"].size).to eq(0)
        end
      end

      describe "filtering" do
        describe "by cohort" do
          let(:cohort_2023) { create(:cohort, start_year: 2023) }
          let(:cohort_2024) { create(:cohort, start_year: 2024) }
          let(:cohort_2025) { create(:cohort, start_year: 2025) }

          it "returns statements for the specified cohort" do
            create(:statement, lead_provider: current_lead_provider, cohort: cohort_2023)
            create(:statement, lead_provider: current_lead_provider, cohort: cohort_2024)
            create(:statement, lead_provider: current_lead_provider, cohort: cohort_2025)

            api_get("/api/v3/statements", params: { filter: { cohort: "2023,2024" } })

            expect(parsed_response["data"].size).to eq(2)
          end
        end

        describe "by updated_since" do
          it "returns statements updated since the specified date" do
            create(:statement, lead_provider: current_lead_provider, updated_at: 2.hours.ago)

            api_get("/api/v3/statements", params: { filter: { updated_since: 1.hour.ago.iso8601 } })

            expect(parsed_response["data"].size).to be_zero
          end

          it "returns 400 - bad request for invalid updated_since" do
            api_get("/api/v3/statements", params: { filter: { updated_since: "invalid" } })

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

      context "with pagination" do
        before do
          create_list(:statement, 8, lead_provider: current_lead_provider)
        end

        it "returns 5 statements on page 1" do
          api_get("/api/v3/statements", params: { page: { per_page: 5, page: 1 } })

          expect(response.status).to eq 200
          expect(parsed_response["data"].size).to eq(5)
        end

        it "returns 3 statements on page 2" do
          api_get("/api/v3/statements", params: { page: { per_page: 5, page: 2 } })

          expect(response.status).to eq 200
          expect(parsed_response["data"].size).to eq(3)
        end

        it "returns empty for page 3" do
          api_get("/api/v3/statements", params: { page: { per_page: 5, page: 3 } })

          expect(response.status).to eq 200
          expect(parsed_response["data"].size).to eq(0)
        end

        it "returns error when requesting page -1" do
          api_get("/api/v3/statements", params: { page: { per_page: 5, page: -1 } })

          expect(response.status).to eq 400
          expect(parsed_response["errors"].size).to eq(1)
          expect(parsed_response["errors"][0]["title"]).to eql("Bad request")
          expect(parsed_response["errors"][0]["detail"]).to eql("The '#/page[page]' and '#/page[per_page]' parameter values must be a valid positive number")
        end
      end
    end

    context "when unauthorized" do
      it "returns 401 - unauthorized" do
        api_get("/api/v3/statements", token: "incorrect-token")

        expect(response.status).to eq 401
        expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
        expect(response.content_type).to eql("application/json")
      end
    end
  end

  describe "GET /api/v3/statements/:id" do
    describe "GET /api/v1/applications/:id" do
      let(:resource) { create(:statement, lead_provider: current_lead_provider) }
      let(:resource_id) { resource.ecf_id }

      def path(id = nil)
        api_v3_statement_path(id)
      end

      it_behaves_like "an API show endpoint", Statements::Query, API::StatementSerializer
    end
  end
end
