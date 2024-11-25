require "rails_helper"

RSpec.describe Applications::Query do
  describe "#applications" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns all applications" do
      application1 = create(:application, lead_provider:)
      application2 = create(:application, lead_provider:)

      query = described_class.new
      expect(query.applications).to contain_exactly(application1, application2)
    end

    it "orders applications by created_at in ascending order" do
      application1 = create(:application, lead_provider:)
      application2 = travel_to(1.hour.ago) { create(:application, lead_provider:) }
      application3 = travel_to(1.minute.ago) { create(:application, lead_provider:) }

      query = described_class.new
      expect(query.applications).to eq([application2, application3, application1])
    end

    describe "filtering" do
      describe "lead provider" do
        it "filters by lead provider" do
          application = create(:application, lead_provider:)
          create(:application, lead_provider: create(:lead_provider))

          query = described_class.new(lead_provider:)
          expect(query.applications).to contain_exactly(application)
        end

        it "doesn't filter by lead provider when none supplied" do
          condition_string = %("applications"."lead_provider_id")

          expect(described_class.new(lead_provider:).scope.to_sql).to include(condition_string)
          expect(described_class.new.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by lead provider if none is supplied" do
          condition_string = %("lead_provider_id")
          query = described_class.new

          expect(query.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by lead provider if an empty string is supplied" do
          condition_string = %("lead_provider_id")
          query = described_class.new(lead_provider: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      describe "updated since" do
        it "filters by updated since" do
          travel_to(2.days.ago) { create(:application, lead_provider:) }

          application = create(:application, lead_provider:, updated_at: Time.zone.now)
          application.user.update!(updated_at: 2.days.ago)

          query = described_class.new(lead_provider:, updated_since: 1.day.ago)

          expect(query.applications).to contain_exactly(application)
        end

        it "doesn't filter by lead provider when none supplied" do
          condition_string = %("applications"."updated_at" >=)

          expect(described_class.new(updated_since: 2.days.ago).scope.to_sql).to include(condition_string)
          expect(described_class.new.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by updated_since if blank" do
          condition_string = %("updated_at")
          query = described_class.new(updated_since: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end

        context "when user was updated recently" do
          let(:user) { create(:user) }

          it "filters by user.updated_at" do
            application1 = travel_to(10.days.ago) do
              create(:application, lead_provider:)
            end
            application2 = travel_to(5.days.ago) do
              create(:application, lead_provider:)
            end

            query = described_class.new(lead_provider:, updated_since: 7.days.ago)
            expect(query.applications).to contain_exactly(application2)

            application1.user.update!(updated_at: 12.days.ago, significantly_updated_at: 1.day.ago)

            query = described_class.new(lead_provider:, updated_since: 2.days.ago)
            expect(query.applications).to contain_exactly(application1)
          end
        end
      end

      context "when filtering by cohort" do
        let(:cohort_2023) { create(:cohort, start_year: 2023) }
        let(:cohort_2024) { create(:cohort, start_year: 2024) }
        let(:cohort_2025) { create(:cohort, start_year: 2025) }

        it "filters by cohort" do
          create(:application, cohort: cohort_2023)
          application = create(:application, cohort: cohort_2024)
          query = described_class.new(cohort_start_years: "2024")

          expect(query.applications).to contain_exactly(application)
        end

        it "filters by multiple cohorts" do
          application1 = create(:application, cohort: cohort_2023)
          application2 = create(:application, cohort: cohort_2024)
          create(:application, cohort: cohort_2025)
          query = described_class.new(cohort_start_years: "2023,2024")

          expect(query.applications).to contain_exactly(application1, application2)
        end

        it "returns no applications if no cohorts are found" do
          query = described_class.new(cohort_start_years: "0000")

          expect(query.applications).to be_empty
        end

        it "doesn't filter by cohort when none supplied" do
          condition_string = %("cohort"."start_year")

          expect(described_class.new(cohort_start_years: 2021).scope.to_sql).to include(condition_string)
          expect(described_class.new.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by cohort if blank" do
          condition_string = %("start_year")
          query = described_class.new(cohort_start_years: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      context "when filtering by lead_provider_approval_status" do
        it "filters by lead_provider_approval_status" do
          create(:application, :pending)
          application = create(:application, :accepted)
          query = described_class.new(lead_provider_approval_status: "accepted")

          expect(query.applications).to contain_exactly(application)
        end

        it "filters by multiple lead_provider_approval_status" do
          application1 = create(:application, :accepted)
          application2 = create(:application, :rejected)
          create(:application, :pending)
          query = described_class.new(lead_provider_approval_status: "accepted,rejected")

          expect(query.applications).to contain_exactly(application1, application2)
        end

        it "returns no applications if no lead_provider_approval_status are found" do
          create(:application, :pending)
          query = described_class.new(lead_provider_approval_status: "unknown")

          expect(query.applications).to be_empty
        end

        it "doesn't filter by lead_provider_approval_status when none supplied" do
          condition_string = %("lead_provider_approval_status")

          expect(described_class.new(lead_provider_approval_status: "pending").scope.to_sql).to include(condition_string)
          expect(described_class.new.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by lead_provider_approval_status if blank" do
          condition_string = %("lead_provider_approval_status")
          query = described_class.new(lead_provider_approval_status: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      context "when filtering by participant_id" do
        it "filters by participant_id" do
          create(:application, user: create(:user))
          application = create(:application, user: create(:user))
          query = described_class.new(participant_ids: application.user.ecf_id)

          expect(query.applications).to contain_exactly(application)
        end

        it "filters by multiple participant_ids" do
          application1 = create(:application, user: create(:user))
          application2 = create(:application, user: create(:user))
          create(:application, user: create(:user))
          query = described_class.new(participant_ids: [application1.user.ecf_id, application2.user.ecf_id].join(","))

          expect(query.applications).to contain_exactly(application1, application2)
        end

        it "returns no applications if no participants are found" do
          query = described_class.new(participant_ids: SecureRandom.uuid)

          expect(query.applications).to be_empty
        end

        it "doesn't filter by participant_ids when none supplied" do
          condition_string = %("ecf_id")

          expect(described_class.new(participant_ids: SecureRandom.uuid).scope.to_sql).to include(condition_string)
          expect(described_class.new.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by participant_ids if blank" do
          condition_string = %("ecf_id")
          query = described_class.new(participant_ids: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end
    end

    describe "sorting" do
      let(:application1) { travel_to(1.month.ago) { create(:application) } }
      let(:application2) { travel_to(1.week.ago) { create(:application) } }
      let(:application3) { create(:application) }
      let(:sort) { nil }

      subject(:applications) { described_class.new(sort:).applications }

      it { is_expected.to eq([application1, application2, application3]) }

      context "when sorting by created at, descending" do
        let(:sort) { "-created_at" }

        it { is_expected.to eq([application3, application2, application1]) }
      end

      context "when sorting by updated at, ascending" do
        let(:sort) { "+updated_at" }

        before do
          application1.update!(updated_at: 1.day.from_now)
          application2.update!(updated_at: 2.days.from_now)
        end

        it { is_expected.to eq([application3, application1, application2]) }
      end

      context "when sorting by multiple attributes" do
        let(:sort) { "+updated_at,-created_at" }

        before do
          application1.update!(updated_at: 1.day.from_now)
          application2.update!(updated_at: application1.updated_at)
          application3.update!(updated_at: 2.days.from_now)

          application2.update!(created_at: 1.day.from_now)
          application1.update!(created_at: 1.day.ago)
        end

        it { expect(applications).to eq([application2, application1, application3]) }
      end
    end

    describe "transient_previously_funded" do
      let(:course) { create(:course, :senior_leadership) }
      let!(:application) { create(:application, lead_provider:, course:) }
      let(:query_applications) { described_class.new(lead_provider:).applications }
      let(:returned_application) { query_applications.find(application.id) }

      it { expect(returned_application).not_to be_transient_previously_funded }

      context "when there is a previous, rejected application that was eligible for funding" do
        before do
          create(
            :application,
            :rejected,
            lead_provider:,
            user_id: application.user_id,
            eligible_for_funding: true,
            course: application.course,
          )
        end

        it { expect(returned_application).not_to be_transient_previously_funded }
      end

      context "when there is a previous, accepted application that was not eligible for funding" do
        before do
          create(
            :application,
            :accepted,
            lead_provider:,
            user_id: application.user_id,
            eligible_for_funding: false,
            course: application.course,
          )
        end

        it { expect(returned_application).not_to be_transient_previously_funded }
      end

      context "when there is a previous, accepted application that was eligible for funding in a different (not rebranded) course" do
        before do
          create(
            :application,
            :accepted,
            lead_provider:,
            user_id: application.user_id,
            eligible_for_funding: true,
            course: Course.find_by(identifier: Course::NPQ_LEADING_TEACHING_DEVELOPMENT),
          )
        end

        it { expect(returned_application).not_to be_transient_previously_funded }
      end

      context "when there is a previous, accepted application that was eligible for funding" do
        before do
          create(
            :application,
            :accepted,
            lead_provider:,
            user_id: application.user_id,
            eligible_for_funding: true,
            course: application.course,
          )
        end

        it { expect(returned_application).to be_transient_previously_funded }
      end

      context "when there is a previous, accepted application that was eligible for funding and funded place is `nil`" do
        before do
          create(
            :application,
            :accepted,
            lead_provider:,
            user_id: application.user_id,
            eligible_for_funding: true,
            funded_place: nil,
            course: application.course,
          )
        end

        it { expect(returned_application).to be_transient_previously_funded }
      end

      context "when there is a previous, accepted application that was eligible for funding and funded place is `true`" do
        before do
          create(
            :application,
            :accepted,
            lead_provider:,
            user_id: application.user_id,
            eligible_for_funding: true,
            funded_place: true,
            course: application.course,
          )
        end

        it { expect(returned_application).to be_transient_previously_funded }
      end

      context "when there is a previous, accepted application that was eligible for funding and funded place is `false`" do
        before do
          create(
            :application,
            :accepted,
            lead_provider:,
            user_id: application.user_id,
            eligible_for_funding: true,
            funded_place: false,
            course: application.course,
          )
        end

        it { expect(returned_application).not_to be_transient_previously_funded }
      end

      context "when there is a previous, accepted application that was eligible for funding on a rebranded course" do
        let(:course) { Course.find_by(identifier: Course::NPQ_ADDITIONAL_SUPPORT_OFFER) }

        before do
          create(
            :application,
            :accepted,
            lead_provider:,
            user_id: application.user_id,
            eligible_for_funding: true,
            course:,
          )
        end

        it { expect(returned_application).to be_transient_previously_funded }
      end
    end
  end

  describe "#application" do
    let(:lead_provider) { create(:lead_provider) }

    it "raises an error if no `id` or `ecf_id` is provided" do
      query = described_class.new
      expect { query.application }.to raise_error(ArgumentError).with_message("id or ecf_id needed")
    end

    it "returns the application using the `id`" do
      application = create(:application, lead_provider:)

      query = described_class.new
      expect(query.application(id: application.id)).to eq(application)
    end

    it "returns the application using the `ecf_id`" do
      application = create(:application, lead_provider:)

      query = described_class.new
      expect(query.application(ecf_id: application.ecf_id)).to eq(application)
    end

    it "returns the application for a `lead_provider`" do
      application = create(:application, lead_provider:)

      query = described_class.new(lead_provider:)
      expect(query.application(id: application.id)).to eq(application)
    end

    it "raises an error if the application does not exist" do
      query = described_class.new
      expect { query.application(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the application is not in the filtered query" do
      other_lead_provider = create(:lead_provider)
      other_application = create(:application, lead_provider: other_lead_provider)

      query = described_class.new(lead_provider:)
      expect { query.application(id: other_application.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
