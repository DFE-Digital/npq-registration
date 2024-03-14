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
          expect(parsed_response["data"][0]["id"]).to eq(statement1.id)
          expect(parsed_response["data"][1]["id"]).to eq(statement2.id)
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
            create(:statement, lead_provider: current_lead_provider, updated_at: 6.hours.ago)
            create(:statement, lead_provider: current_lead_provider, updated_at: 3.hours.ago)
            create(:statement, lead_provider: current_lead_provider, updated_at: 1.hour.ago)

            api_get("/api/v3/statements", params: { filter: { updated_since: 4.hours.ago } })

            expect(parsed_response["data"].size).to eq(2)
          end
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
    context "when authorized" do
      context "when statement exists" do
        let!(:statement) { create(:statement, lead_provider: current_lead_provider) }

        it "returns statement" do
          api_get("/api/v3/statements/#{statement.id}")

          expect(response.status).to eq 200
          expect(response.content_type).to eql("application/json")
          expect(parsed_response["data"]["id"]).to eq(statement.id)
        end
      end

      context "when statement does not exist", exceptions_app: true do
        it "returns not found" do
          api_get("/api/v3/statements/123XXX")

          expect(response.status).to eq 404
        end
      end
    end

    context "when unauthorized" do
      let!(:statement) { create(:statement, lead_provider: current_lead_provider) }

      it "returns 401 - unauthorized" do
        api_get("/api/v3/statements/#{statement.id}", token: "incorrect-token")

        expect(response.status).to eq 401
        expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
        expect(response.content_type).to eql("application/json")
      end
    end
  end
end
