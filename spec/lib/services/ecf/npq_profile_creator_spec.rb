require "rails_helper"

RSpec.describe Ecf::NpqProfileCreator do
  subject { described_class.new(application:) }

  let(:user) do
    User.create!(
      email: "john.doe@example.com",
      full_name: "John Doe",
      ecf_id: "c72fef68-e92f-40ff-9d73-b0e551006e32",
      trn: "1234567",
      trn_verified: true,
      active_alert: true,
      date_of_birth: Date.new(1980, 12, 13),
      national_insurance_number: "AB123456C",
    )
  end
  let(:course) { Course.create!(name: "Some course", ecf_id: "c8c9c80b-375b-48fc-92ea-670c2cb4da5c") }
  let(:lead_provider) { LeadProvider.create!(name: "Some lead provider", ecf_id: "0d2ac426-e67c-47ad-b53b-a214ec7f999a") }
  let(:itt_provider) { create :itt_provider }
  let(:school) { create(:school) }
  let(:teacher_catchment_country) { AutocompleteCountries.names.sample }

  let(:application) do
    Application.create!(
      user:,
      course:,
      lead_provider:,
      school:,
      ukprn: school.ukprn,
      headteacher_status: "no",
      eligible_for_funding: true,
      funding_choice: "trust",
      targeted_delivery_funding_eligibility: true,
      works_in_childcare: false,
      kind_of_nursery: nil,
      itt_provider:,
      lead_mentor: false,
      DEPRECATED_private_childcare_provider_urn: nil,
      private_childcare_provider_id: nil,
      funding_eligiblity_status_code: FundingEligibility::FUNDED_ELIGIBILITY_RESULT,
      teacher_catchment: "other",
      teacher_catchment_country:,
      employment_type: SecureRandom.uuid,
      employment_role: SecureRandom.uuid,
      employer_name: SecureRandom.uuid,
      primary_establishment: false,
      number_of_pupils: 0,
      tsf_primary_plus_eligibility: false,
    )
  end

  describe "#call" do
    let(:request_body) do
      {
        data: {
          type: "npq_profiles",
          relationships: {
            user: {
              data: {
                type: "users",
                id: "c72fef68-e92f-40ff-9d73-b0e551006e32",
              },
            },
            npq_course: {
              data: {
                type: "npq_courses",
                id: application.course.ecf_id,
              },
            },
            npq_lead_provider: {
              data: {
                type: "npq_lead_providers",
                id: application.lead_provider.ecf_id,
              },
            },
          },
          attributes: {
            teacher_reference_number: "1234567",
            teacher_reference_number_verified: true,
            active_alert: true,
            date_of_birth: user.date_of_birth.iso8601,
            national_insurance_number: user.national_insurance_number,
            school_urn: application.school_urn,
            school_ukprn: application.ukprn,
            headteacher_status: "no",
            eligible_for_funding: true,
            funding_choice: "trust",
            works_in_school: application.works_in_school,
            employer_name: application.employer_name,
            employment_role: application.employment_role,
            employment_type: application.employment_type,
            targeted_delivery_funding_eligibility: true,
            works_in_childcare: false,
            kind_of_nursery: nil,
            private_childcare_provider_urn: nil,
            funding_eligiblity_status_code: "funded",
            teacher_catchment: "other",
            teacher_catchment_country:,
            itt_provider: itt_provider.legal_name,
            lead_mentor: false,
            primary_establishment: false,
            number_of_pupils: 0,
            tsf_primary_plus_eligibility: false,
          },
        },
      }.to_json
    end

    let(:response_body) do
      {
        data: {
          type: "npq_profiles",
          id: "d7236e96-4ff8-4e12-9cf9-7592b9699c94",
        },
      }.to_json
    end

    before do
      stub_request(:post, "https://ecf-app.gov.uk/api/v1/npq-profiles")
        .with(
          body: request_body,
          headers: {
            "Accept" => "application/vnd.api+json",
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            "Content-Type" => "application/vnd.api+json",
          },
        )
        .to_return(
          status: response_code,
          body: response_body.to_json,
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

    context "when authorized" do
      let(:response_code) { 200 }

      let(:response_body) do
        {
          data: {
            type: "npq_profiles",
            id: "d7236e96-4ff8-4e12-9cf9-7592b9699c94",
          },
        }
      end

      it "sets application.ecf_id with returned guid" do
        expect {
          subject.call
        }.to change(application, :ecf_id).to("d7236e96-4ff8-4e12-9cf9-7592b9699c94")
      end

      it "creates a EcfSyncRequestLog with status :success" do
        expect {
          subject.call
        }.to change(EcfSyncRequestLog, :count).by(1)

        expect(
          EcfSyncRequestLog.last.slice(:syncable, :status, :error_messages, :response_body, :sync_type),
        ).to match(
          "syncable" => application,
          "status" => "success",
          "error_messages" => [],
          "response_body" => nil,
          "sync_type" => "application_creation",
        )
      end

      context "when save fails" do
        let(:error_array) do
          [
            {
              "title": "Participant identity blank",
              "detail": "must exist",
            },
            {
              "title": "NPQ lead provider blank",
              "detail": "must exist",
            },
            {
              "title": "NPQ course blank",
              "detail": "must exist",
            },
          ]
        end
        let(:response_body) do
          {
            "errors": error_array,
          }
        end

        let(:response_code) { 400 }

        it "raises an error" do
          expect {
            subject.call
          }.to raise_error(JsonApiClient::Errors::ClientError)
        end

        it "does not set application.ecf_id " do
          expect {
            begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
          }.not_to change(application, :ecf_id)
        end

        it "creates a EcfSyncRequestLog with status :failed" do
          expect {
            begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
          }.to change(EcfSyncRequestLog, :count).by(1)

          expect(
            EcfSyncRequestLog.last.slice(:syncable, :status, :error_messages, :response_body, :sync_type),
          ).to match(
            "syncable" => application,
            "status" => "failed",
            "error_messages" => ["JsonApiClient::Errors::ClientError - Participant identity blank; NPQ lead provider blank; NPQ course blank"],
            "response_body" => response_body,
            "sync_type" => "application_creation",
          )
        end
      end
    end

    context "when unauthorized" do
      let(:response_code) { 401 }

      let(:response_body) do
        {
          "error" => "HTTP Token: Access denied",
        }
      end

      it "raises an error" do
        expect {
          subject.call
        }.to raise_error(JsonApiClient::Errors::ClientError)
      end

      it "does not set application.ecf_id " do
        expect {
          begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
        }.not_to change(application, :ecf_id)
      end

      it "creates a EcfSyncRequestLog with status :failed" do
        expect {
          begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
        }.to change(EcfSyncRequestLog, :count).by(1)

        expect(
          EcfSyncRequestLog.last.slice(:syncable, :status, :error_messages, :response_body, :sync_type),
        ).to match(
          "syncable" => application,
          "status" => "failed",
          "error_messages" => ["JsonApiClient::Errors::NotAuthorized - JsonApiClient::Errors::NotAuthorized"],
          "response_body" => response_body,
          "sync_type" => "application_creation",
        )
      end
    end
  end
end
