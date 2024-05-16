# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::ApplicationCsvSerializer, type: :serializer do
  subject { described_class.new([application]).call }

  describe "serialization" do
    let(:application) do
      create(:application,
             :accepted,
             :eligible_for_funding,
             targeted_delivery_funding_eligibility: true,
             cohort: create(:cohort))
    end
    let(:rows) { CSV.parse(subject, headers: true) }

    it "returns expected data", :aggregate_failures do
      expect(rows[0]["course_identifier"]).to eql(application.course.identifier)
      expect(rows[0]["email"]).to eql(application.user.email)
      expect(rows[0]["email_validated"]).to eql("true")
      expect(rows[0]["employer_name"]).to eql(application.employer_name)
      expect(rows[0]["employment_role"]).to eql(application.employment_role)
      expect(rows[0]["full_name"]).to eql(application.user.full_name)
      expect(rows[0]["funding_choice"]).to eql(application.funding_choice)
      expect(rows[0]["headteacher_status"]).to eql(application.headteacher_status)
      expect(rows[0]["ineligible_for_funding_reason"]).to eql(application.ineligible_for_funding_reason)
      expect(rows[0]["participant_id"]).to eql(application.user.ecf_id)
      expect(rows[0]["private_childcare_provider_urn"]).to eql(application.private_childcare_provider&.provider_urn)
      expect(rows[0]["teacher_reference_number"]).to eql(application.user.trn)
      expect(rows[0]["teacher_reference_number_validated"]).to eql(application.user.trn_verified.to_s)
      expect(rows[0]["school_urn"]).to eql(application.school.urn)
      expect(rows[0]["school_ukprn"]).to eql(application.school.ukprn)
      expect(rows[0]["status"]).to eql(application.lead_provider_approval_status)
      expect(rows[0]["works_in_school"]).to eql(application.works_in_school.to_s)
      expect(rows[0]["eligible_for_funding"]).to eql(application.eligible_for_funding.to_s)
      expect(rows[0]["targeted_delivery_funding_eligibility"]).to eql(application.targeted_delivery_funding_eligibility.to_s)
      expect(rows[0]["teacher_catchment"]).to eq "true"
      expect(rows[0]["teacher_catchment_country"]).to eql("United Kingdom of Great Britain and Northern Ireland")
      expect(rows[0]["teacher_catchment_iso_country_code"]).to eql("GBR")
      expect(rows[0]["itt_provider"]).to eql(application.itt_provider.legal_name)
      expect(rows[0]["lead_mentor"]).to eql(application.lead_mentor.to_s)
    end
  end

  describe "#updated_at" do
    let(:application) { create(:application, targeted_delivery_funding_eligibility: true) }
    let(:user) { application.user }
    let(:updated_at_attribute) { CSV.parse(subject, headers: true)[0]["updated_at"] }

    context "when application touched" do
      before do
        ActiveRecord::Base.no_touching do
          user.update!(updated_at: 10.days.ago)
        end
      end

      it "considers updated_at of the application" do
        expect(Time.zone.parse(updated_at_attribute)).to be_within(1.minute).of(Time.zone.now)
      end
    end

    context "when user touched" do
      before do
        ActiveRecord::Base.no_touching do
          application.update!(updated_at: 5.days.ago)
          user.update!(updated_at: 1.day.ago)
        end
      end

      it "considers updated_at of user" do
        expect(Time.zone.parse(updated_at_attribute)).to be_within(1.minute).of(1.day.ago)
      end
    end
  end
end
