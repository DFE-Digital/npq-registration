require "rails_helper"

RSpec.describe Declarations::Query do
  describe "#declarations" do
    it "returns all declarations" do
      declaration1 = create(:declaration)
      declaration2 = create(:declaration)

      query = Declarations::Query.new
      expect(query.declarations).to contain_exactly(declaration1, declaration2)
    end

    it "orders declarations by created_at in ascending order" do
      declaration1 = create(:declaration)
      declaration2 = travel_to(1.hour.ago) { create(:declaration) }
      declaration3 = travel_to(1.minute.ago) { create(:declaration) }

      query = Declarations::Query.new
      expect(query.declarations).to eq([declaration2, declaration3, declaration1])
    end

    describe "filtering" do
      describe "lead provider" do
        it "filters by lead provider" do
          declaration = create(:declaration)
          create(:declaration, lead_provider: create(:lead_provider))

          query = Declarations::Query.new(lead_provider: declaration.lead_provider)
          expect(query.declarations).to contain_exactly(declaration)
        end

        it "doesn't filter by lead provider when none supplied" do
          condition_string = %("declarations"."lead_provider_id" =)

          expect(Declarations::Query.new(lead_provider: create(:lead_provider)).scope.to_sql).to include(condition_string)
          expect(Declarations::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end

      describe "updated since" do
        it "filters by updated since" do
          create(:declaration, updated_at: 2.days.ago)
          declaration = create(:declaration, updated_at: Time.zone.now)

          query = Declarations::Query.new(updated_since: 1.day.ago)

          expect(query.declarations).to contain_exactly(declaration)
        end

        it "doesn't filter by updated since when none supplied" do
          condition_string = %("declarations"."updated_at" >=)

          expect(Declarations::Query.new(updated_since: 2.days.ago).scope.to_sql).to include(condition_string)
          expect(Declarations::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end

      context "when filtering by cohort" do
        let(:cohort_2023) { create(:cohort, start_year: 2023) }
        let(:cohort_2024) { create(:cohort, start_year: 2024) }
        let(:cohort_2025) { create(:cohort, start_year: 2025) }

        it "filters by cohort" do
          create(:declaration, cohort: cohort_2023)
          declaration = create(:declaration, cohort: cohort_2024)
          query = Declarations::Query.new(cohort_start_years: "2024")

          expect(query.declarations).to contain_exactly(declaration)
        end

        it "filters by multiple cohorts" do
          declaration1 = create(:declaration, cohort: cohort_2023)
          declaration2 = create(:declaration, cohort: cohort_2024)
          create(:declaration, cohort: cohort_2025)
          query = Declarations::Query.new(cohort_start_years: "2023,2024")

          expect(query.declarations).to contain_exactly(declaration1, declaration2)
        end

        it "returns no declarations if no cohorts are found" do
          query = Declarations::Query.new(cohort_start_years: "0000")

          expect(query.declarations).to be_empty
        end

        it "doesn't filter by cohort when none supplied" do
          condition_string = %("cohort"."start_year" =)

          expect(Declarations::Query.new(cohort_start_years: 2021).scope.to_sql).to include(condition_string)
          expect(Declarations::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end

      context "when filtering by participant_id" do
        it "filters by participant_id" do
          create(:declaration, application: create(:application, user: create(:user)))
          declaration = create(:declaration, application: create(:application, user: create(:user)))
          query = Declarations::Query.new(participant_ids: declaration.user.ecf_id)

          expect(query.declarations).to contain_exactly(declaration)
        end

        it "filters by multiple participant_ids" do
          declaration2 = create(:declaration, application: create(:application, user: create(:user)))
          declaration1 = create(:declaration, application: create(:application, user: create(:user)))
          create(:declaration, application: create(:application, user: create(:user)))
          query = Declarations::Query.new(participant_ids: [declaration1.user.ecf_id, declaration2.user.ecf_id].join(","))

          expect(query.declarations).to contain_exactly(declaration1, declaration2)
        end

        it "returns no declarations if no participants are found" do
          query = Declarations::Query.new(participant_ids: SecureRandom.uuid)

          expect(query.declarations).to be_empty
        end

        it "doesn't filter by participant_ids when none supplied" do
          condition_string = %("user"."ecf_id" =)

          expect(Declarations::Query.new(participant_ids: SecureRandom.uuid).scope.to_sql).to include(condition_string)
          expect(Declarations::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end
    end
  end

  describe "#declaration" do
    let(:declaration) { create(:declaration) }
    let(:lead_provider) { declaration.lead_provider }
    let(:query) { Declarations::Query.new(lead_provider:) }

    it "returns a declaration by the given id" do
      expect(query.declaration(ecf_id: declaration.ecf_id)).to eq(declaration)
      expect(query.declaration(id: declaration.id)).to eq(declaration)
    end

    it "raises an error if the declaration does not exist" do
      expect { query.declaration(ecf_id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.declaration(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the declaration is not in the filtered query" do
      other_declaration = create(:declaration)

      expect { query.declaration(ecf_id: other_declaration.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.declaration(id: other_declaration.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if neither an ecf_id or id is supplied" do
      expect { query.declaration }.to raise_error(ArgumentError, "id or ecf_id needed")
    end
  end
end