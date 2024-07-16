require "rails_helper"

RSpec.describe Applications::Query do
  describe "#applications" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns all applications" do
      application1 = create(:application, lead_provider:)
      application2 = create(:application, lead_provider:)

      query = Applications::Query.new
      expect(query.applications).to contain_exactly(application1, application2)
    end

    it "orders applications by created_at in ascending order" do
      application1 = create(:application, lead_provider:)
      application2 = travel_to(1.hour.ago) { create(:application, lead_provider:) }
      application3 = travel_to(1.minute.ago) { create(:application, lead_provider:) }

      query = Applications::Query.new
      expect(query.applications).to eq([application2, application3, application1])
    end

    describe "filtering" do
      describe "lead provider" do
        it "filters by lead provider" do
          application = create(:application, lead_provider:)
          create(:application, lead_provider: create(:lead_provider))

          query = Applications::Query.new(lead_provider:)
          expect(query.applications).to contain_exactly(application)
        end

        it "doesn't filter by lead provider when none supplied" do
          condition_string = %("applications"."lead_provider_id" =)

          expect(Applications::Query.new(lead_provider:).scope.to_sql).to include(condition_string)
          expect(Applications::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end

      describe "updated since" do
        it "filters by updated since" do
          create(:application, lead_provider:, updated_at: 2.days.ago)
          application = create(:application, lead_provider:, updated_at: Time.zone.now)

          query = Applications::Query.new(lead_provider:, updated_since: 1.day.ago)

          expect(query.applications).to contain_exactly(application)
        end

        it "doesn't filter by lead provider when none supplied" do
          condition_string = %("applications"."updated_at" >=)

          expect(Applications::Query.new(updated_since: 2.days.ago).scope.to_sql).to include(condition_string)
          expect(Applications::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end

      context "when filtering by cohort" do
        let(:cohort_2023) { create(:cohort, start_year: 2023) }
        let(:cohort_2024) { create(:cohort, start_year: 2024) }
        let(:cohort_2025) { create(:cohort, start_year: 2025) }

        it "filters by cohort" do
          create(:application, cohort: cohort_2023)
          application = create(:application, cohort: cohort_2024)
          query = Applications::Query.new(cohort_start_years: "2024")

          expect(query.applications).to contain_exactly(application)
        end

        it "filters by multiple cohorts" do
          application1 = create(:application, cohort: cohort_2023)
          application2 = create(:application, cohort: cohort_2024)
          create(:application, cohort: cohort_2025)
          query = Applications::Query.new(cohort_start_years: "2023,2024")

          expect(query.applications).to contain_exactly(application1, application2)
        end

        it "returns no applications if no cohorts are found" do
          query = Applications::Query.new(cohort_start_years: "0000")

          expect(query.applications).to be_empty
        end

        it "doesn't filter by cohort when none supplied" do
          condition_string = %("cohort"."start_year" =)

          expect(Applications::Query.new(cohort_start_years: 2021).scope.to_sql).to include(condition_string)
          expect(Applications::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end

      context "when filtering by lead_provider_approval_status" do
        it "filters by lead_provider_approval_status" do
          create(:application, :pending)
          application = create(:application, :accepted)
          query = Applications::Query.new(lead_provider_approval_status: "accepted")

          expect(query.applications).to contain_exactly(application)
        end

        it "filters by multiple lead_provider_approval_status" do
          application1 = create(:application, :accepted)
          application2 = create(:application, :rejected)
          create(:application, :pending)
          query = Applications::Query.new(lead_provider_approval_status: "accepted,rejected")

          expect(query.applications).to contain_exactly(application1, application2)
        end

        it "returns no applications if no lead_provider_approval_status are found" do
          create(:application, :pending)
          query = Applications::Query.new(lead_provider_approval_status: "unknown")

          expect(query.applications).to be_empty
        end

        it "doesn't filter by lead_provider_approval_status when none supplied" do
          condition_string = %("applications"."lead_provider_approval_status" =)

          expect(Applications::Query.new(lead_provider_approval_status: "pending").scope.to_sql).to include(condition_string)
          expect(Applications::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end

      context "when filtering by participant_id" do
        it "filters by participant_id" do
          create(:application, user: create(:user))
          application = create(:application, user: create(:user))
          query = Applications::Query.new(participant_ids: application.user.ecf_id)

          expect(query.applications).to contain_exactly(application)
        end

        it "filters by multiple participant_ids" do
          application1 = create(:application, user: create(:user))
          application2 = create(:application, user: create(:user))
          create(:application, user: create(:user))
          query = Applications::Query.new(participant_ids: [application1.user.ecf_id, application2.user.ecf_id].join(","))

          expect(query.applications).to contain_exactly(application1, application2)
        end

        it "returns no applications if no participants are found" do
          query = Applications::Query.new(participant_ids: SecureRandom.uuid)

          expect(query.applications).to be_empty
        end

        it "doesn't filter by participant_ids when none supplied" do
          condition_string = %("user"."ecf_id" =)

          expect(Applications::Query.new(participant_ids: SecureRandom.uuid).scope.to_sql).to include(condition_string)
          expect(Applications::Query.new.scope.to_sql).not_to include(condition_string)
        end
      end
    end

    describe "sorting" do
      let(:application1) { travel_to(1.month.ago) { create(:application) } }
      let(:application2) { travel_to(1.week.ago) { create(:application) } }
      let(:application3) { create(:application) }
      let(:sort) { nil }

      subject(:applications) { Applications::Query.new(sort:).applications }

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
      let(:course) { create(:course, :sl) }
      let!(:application) { create(:application, lead_provider:, course:) }
      let(:query_applications) { Applications::Query.new(lead_provider:).applications }
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
      query = Applications::Query.new
      expect { query.application }.to raise_error(ArgumentError).with_message("id or ecf_id needed")
    end

    it "returns the application using the `id`" do
      application = create(:application, lead_provider:)

      query = Applications::Query.new
      expect(query.application(id: application.id)).to eq(application)
    end

    it "returns the application using the `ecf_id`" do
      application = create(:application, lead_provider:)

      query = Applications::Query.new
      expect(query.application(ecf_id: application.ecf_id)).to eq(application)
    end

    it "returns the application for a `lead_provider`" do
      application = create(:application, lead_provider:)

      query = Applications::Query.new(lead_provider:)
      expect(query.application(id: application.id)).to eq(application)
    end

    it "raises an error if the application does not exist" do
      query = Applications::Query.new
      expect { query.application(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the application is not in the filtered query" do
      other_lead_provider = create(:lead_provider)
      other_application = create(:application, lead_provider: other_lead_provider)

      query = Applications::Query.new(lead_provider:)
      expect { query.application(id: other_application.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
