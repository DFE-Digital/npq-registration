require "rails_helper"

RSpec.describe ParticipantOutcomes::Query do
  describe "#participant_outcomes" do
    it "returns all outcomes" do
      outcome1 = create(:participant_outcome)
      outcome2 = create(:participant_outcome)

      query = described_class.new
      expect(query.participant_outcomes).to contain_exactly(outcome1, outcome2)
    end

    it "orders outcomes by created_at in ascending order" do
      outcome1 = create(:participant_outcome)
      outcome2 = travel_to(1.hour.ago) { create(:participant_outcome) }
      outcome3 = travel_to(1.minute.ago) { create(:participant_outcome) }

      query = described_class.new
      expect(query.participant_outcomes).to eq([outcome2, outcome3, outcome1])
    end

    describe "filtering" do
      describe "lead provider" do
        it "filters by lead provider" do
          outcome = create(:participant_outcome)
          create(:participant_outcome, declaration: create(:declaration, lead_provider: create(:lead_provider)))

          query = described_class.new(lead_provider: outcome.lead_provider)
          expect(query.participant_outcomes).to contain_exactly(outcome)
        end

        it "doesn't filter by lead provider when none supplied" do
          condition_string = %("lead_provider_id")

          expect(described_class.new(lead_provider: create(:lead_provider)).scope.to_sql).to include(condition_string)
          expect(described_class.new.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by lead provider if an empty string is supplied" do
          condition_string = %("lead_provider_id")
          query = described_class.new(lead_provider: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      describe "created since" do
        it "filters by created since" do
          travel_to(2.days.ago) { create(:participant_outcome) }
          outcome = create(:participant_outcome)

          query = described_class.new(created_since: 1.day.ago)

          expect(query.participant_outcomes).to contain_exactly(outcome)
        end

        it "doesn't filter by created since when none supplied" do
          condition_string = %("created_at")

          expect(described_class.new(created_since: 2.days.ago).scope.to_sql).to include(condition_string)
          expect(described_class.new.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by created since if an empty string is supplied" do
          condition_string = %("created_at")
          query = described_class.new(created_since: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      context "when filtering by participant_ids" do
        it "filters by participant_ids" do
          create(:participant_outcome, declaration: create(:declaration, user: create(:user)))
          outcome = create(:participant_outcome, declaration: create(:declaration, user: create(:user)))
          query = described_class.new(participant_ids: outcome.user.ecf_id)

          expect(query.participant_outcomes).to contain_exactly(outcome)
        end

        it "filters by multiple participant_ids" do
          outcome2 = create(:participant_outcome, declaration: create(:declaration, user: create(:user)))
          outcome1 = create(:participant_outcome, declaration: create(:declaration, user: create(:user)))
          create(:participant_outcome, declaration: create(:declaration, user: create(:user)))
          query = described_class.new(participant_ids: [outcome1.user.ecf_id, outcome2.user.ecf_id].join(","))

          expect(query.participant_outcomes).to contain_exactly(outcome1, outcome2)
        end

        it "returns no outcomes if no participants are found" do
          query = described_class.new(participant_ids: SecureRandom.uuid)

          expect(query.participant_outcomes).to be_empty
        end

        it "doesn't filter by participant_ids when none supplied" do
          condition_string = %("ecf_id")

          expect(described_class.new(participant_ids: SecureRandom.uuid).scope.to_sql).to include(condition_string)
          expect(described_class.new.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by participant_ids if an empty string is supplied" do
          condition_string = %("ecf_id")
          query = described_class.new(participant_ids: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end
    end
  end
end
