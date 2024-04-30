require "rails_helper"

RSpec.describe API::ApplicationSerializer, type: :serializer do
  let(:user) { application.user }
  let(:course) { create(:course) }
  let(:cohort) { build(:cohort) }
  let(:private_childcare_provider) { build(:private_childcare_provider) }
  let(:school) { build(:school) }
  let(:itt_provider) { build(:itt_provider) }
  let(:application) { build(:application, cohort:, course:, private_childcare_provider:, itt_provider:, school:) }

  describe "core attributes" do
    subject(:response) { JSON.parse(described_class.render(application)) }

    it "serializes the `id`" do
      application.ecf_id = "fe1a5280-1b13-4b09-b9c7-e2b01d37e851"

      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
    end

    it "serializes the `type`" do
      expect(response["type"]).to eq("npq_application")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { JSON.parse(described_class.render(application))["attributes"] }

    it "does not serialize `schedule_identifier`" do
      expect(attributes).not_to have_key("schedule_identifier")
    end

    it "serializes the `employer_name`" do
      application.employer_name = "employer"
      expect(attributes["employer_name"]).to eq(application.employer_name)
    end

    it "serializes the `employment_role`" do
      application.employment_role = "role"
      expect(attributes["employment_role"]).to eq(application.employment_role)
    end

    it "serializes the `funding_choice`" do
      application.funding_choice = "school"
      expect(attributes["funding_choice"]).to eq(application.funding_choice)
    end

    it "serializes the `headteacher_status`" do
      application.headteacher_status = "no"
      expect(attributes["headteacher_status"]).to eq(application.headteacher_status)
    end

    it "serializes the `works_in_school`" do
      application.works_in_school = true
      expect(attributes["works_in_school"]).to eq(application.works_in_school)
    end

    it "serializes the `email_validated`" do
      expect(attributes["email_validated"]).to eq(true)
    end

    it "serializes the `status`" do
      application.lead_provider_approval_status = "pending"
      expect(attributes["status"]).to eq(application.lead_provider_approval_status)
    end

    it "serializes the `targeted_delivery_funding_eligibility`" do
      application.targeted_delivery_funding_eligibility = "eligible"
      expect(attributes["targeted_delivery_funding_eligibility"]).to eq(application.targeted_delivery_funding_eligibility)
    end

    it "serializes the `eligible_for_funding`" do
      application.eligible_for_funding = true
      expect(attributes["eligible_for_funding"]).to eq(application.eligible_for_funding)
    end

    it "serializes the `teacher_catchment`" do
      application.teacher_catchment = "england"
      expect(attributes["teacher_catchment"]).to eq(true)
    end

    it "serializes the `teacher_catchment_country`" do
      application.teacher_catchment_country = "country"
      expect(attributes["teacher_catchment_country"]).to eq(application.teacher_catchment_country)
    end

    it "serializes the `teacher_catchment_iso_country_code`" do
      application.teacher_catchment_iso_country_code = "iso"
      expect(attributes["teacher_catchment_iso_country_code"]).to eq(application.teacher_catchment_iso_country_code)
    end

    it "serializes the `lead_mentor`" do
      application.lead_mentor = true
      expect(attributes["lead_mentor"]).to eq(application.lead_mentor)
    end

    describe "cohort serialization" do
      it "serializes the `cohort`" do
        cohort.start_year = 2025
        expect(attributes["cohort"]).to eq(cohort.start_year.to_s)
      end

      context "when `cohort` is `nil`" do
        let(:cohort) { nil }

        it { expect(attributes["cohort"]).to be_nil }
      end
    end

    describe "itt_provider serialization" do
      it "serializes the `itt_provider`" do
        itt_provider.legal_name = "provider"
        expect(attributes["itt_provider"]).to eq(itt_provider.legal_name)
      end

      context "when `itt_provider` is `nil`" do
        let(:itt_provider) { nil }

        it { expect(attributes["itt_provider"]).to be_nil }
      end
    end

    describe "school serialization" do
      it "serializes the `school_urn`" do
        school.urn = "1234567"
        expect(attributes["school_urn"]).to eq(school.urn)
      end

      it "serializes the `school_ukprn`" do
        school.urn = "ukprn"
        expect(attributes["school_ukprn"]).to eq(school.ukprn)
      end

      context "when `school` is `nil`" do
        let(:school) { nil }

        it { expect(attributes["school_urn"]).to be_nil }
        it { expect(attributes["school_ukprn"]).to be_nil }
      end
    end

    describe "course serialization" do
      it "serializes the `course_identifier`" do
        course.identifier = "identifier"
        expect(attributes["course_identifier"]).to eq(course.identifier)
      end
    end

    describe "private_childcare_provider serialization" do
      it "serializes the `private_childcare_provider_urn`" do
        private_childcare_provider.provider_urn = "2345678"
        expect(attributes["private_childcare_provider_urn"]).to eq(private_childcare_provider.provider_urn)
      end

      context "when `private_childcare_provider` is `nil`" do
        let(:private_childcare_provider) { nil }

        it { expect(attributes["private_childcare_provider_urn"]).to be_nil }
      end
    end

    describe "user serialization" do
      it "serializes the `participant_id`" do
        user.ecf_id = SecureRandom.uuid
        expect(attributes["participant_id"]).to eq(user.ecf_id)
      end

      it "serializes the `email`" do
        user.email = "email@address.com"
        expect(attributes["email"]).to eq(user.email)
      end

      it "serializes the `full_name`" do
        user.full_name = "full name"
        expect(attributes["full_name"]).to eq(user.full_name)
      end

      it "serializes the `teacher_reference_number`" do
        user.trn = "1234567"
        expect(attributes["teacher_reference_number"]).to eq(user.trn)
      end

      it "serializes the `teacher_reference_number_validated`" do
        user.trn_verified = true
        expect(attributes["teacher_reference_number_validated"]).to eq(user.trn_verified)
      end
    end

    describe "timestamp serialization" do
      it "serializes the `created_at`" do
        application.created_at = Time.utc(2023, 7, 1, 12, 0, 0)

        expect(attributes["created_at"]).to eq("2023-07-01T12:00:00Z")
      end

      it "serializes the `updated_at`" do
        application.updated_at = Time.utc(2023, 7, 2, 12, 0, 0)

        expect(attributes["updated_at"]).to eq("2023-07-02T12:00:00Z")
      end

      context "when the user was updated after the application" do
        it "serializes the `updated_at` as the user's updated_at" do
          application.updated_at = Time.utc(2023, 7, 2, 12, 0, 0)
          user.updated_at = Time.utc(2024, 7, 2, 12, 0, 0)

          expect(attributes["updated_at"]).to eq("2024-07-02T12:00:00Z")
        end
      end
    end
  end

  context "when serializing the `v3` view" do
    describe "nested attributes" do
      subject(:attributes) { JSON.parse(described_class.render(application, view: :v3))["attributes"] }

      # FIXME: When we migrate schedules we can test this fully.
      it "serializes the `schedule_identifier`" do
        expect(attributes["schedule_identifier"]).to be_nil
      end
    end
  end
end
