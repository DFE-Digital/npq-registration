# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::ApplicationsCsvSerializer, type: :serializer do
  let(:instance) { described_class.new(applications) }

  describe "#serialize" do
    subject(:csv) { instance.serialize }

    let(:applications) do
      create_list(:application, 2,
                  :accepted,
                  :with_private_childcare_provider,
                  employer_name: "Employer Name",
                  employment_role: "Employment Role",
                  funded_place: true)
    end
    let(:rows) { CSV.parse(csv, headers: true) }
    let(:first_application) { applications.first }
    let(:first_row) { rows.first.to_hash.symbolize_keys }

    it { expect(rows.count).to eq(applications.count) }
    it { expect(first_row.values).to all(be_present) }

    it "returns expected data", :aggregate_failures do
      expect(first_row).to eq({
        id: first_application.ecf_id,
        course_identifier: first_application.course.identifier,
        email: first_application.user.email,
        email_validated: "true",
        employer_name: first_application.employer_name,
        employment_role: first_application.employment_role,
        full_name: first_application.user.full_name,
        funded_place: first_application.funded_place.to_s,
        funding_choice: first_application.funding_choice,
        headteacher_status: first_application.headteacher_status,
        ineligible_for_funding_reason: first_application.ineligible_for_funding_reason,
        participant_id: first_application.user.ecf_id,
        private_childcare_provider_urn: first_application.private_childcare_provider.provider_urn,
        teacher_reference_number: first_application.user.trn,
        teacher_reference_number_validated: first_application.user.trn_verified.to_s,
        school_urn: first_application.school.urn,
        school_ukprn: first_application.school.ukprn,
        status: first_application.lead_provider_approval_status,
        works_in_school: first_application.works_in_school.to_s,
        eligible_for_funding: first_application.eligible_for_funding.to_s,
        targeted_delivery_funding_eligibility: first_application.targeted_delivery_funding_eligibility.to_s,
        teacher_catchment: "true",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        itt_provider: first_application.itt_provider.legal_name,
        lead_mentor: first_application.lead_mentor.to_s,
        cohort: first_application.cohort.start_year.to_s,
        created_at: first_application.created_at.rfc3339,
        updated_at: first_application.updated_at.rfc3339,
      })
    end

    describe "updated_at serialization" do
      let(:parsed_updated_at_attribute) { Time.zone.parse(first_row[:updated_at]) }

      context "when the application has been updated more recently than the user" do
        before do
          ActiveRecord::Base.no_touching do
            first_application.user.update!(updated_at: 5.days.ago)
            first_application.update!(updated_at: 1.day.ago)
          end
        end

        it { expect(parsed_updated_at_attribute).to be_within(1.second).of(first_application.updated_at) }
      end

      context "when the user has been updated more recently than the application" do
        before do
          ActiveRecord::Base.no_touching do
            first_application.update!(updated_at: 5.days.ago)
            first_application.user.update!(updated_at: 1.day.ago)
          end
        end

        it { expect(parsed_updated_at_attribute).to be_within(1.second).of(first_application.user.updated_at) }
      end
    end

    describe "created_at serialization" do
      let(:parsed_created_at_attribute) { Time.zone.parse(first_row[:created_at]) }

      it { expect(parsed_created_at_attribute).to be_within(1.second).of(first_application.created_at) }

      context "when the application has been accepted" do
        before do
          ActiveRecord::Base.no_touching do
            first_application.update!(created_at: 5.days.ago)
            first_application.update!(accepted_at: 1.day.ago)
          end
        end

        it { expect(parsed_created_at_attribute).to be_within(1.second).of(first_application.accepted_at) }
      end
    end
  end
end
