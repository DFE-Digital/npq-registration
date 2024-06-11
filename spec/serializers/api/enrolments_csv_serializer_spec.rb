# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::EnrolmentsCsvSerializer, type: :serializer do
  let(:instance) { described_class.new(applications) }

  describe "#serialize" do
    subject(:csv) { instance.serialize }

    let(:applications) { create_list(:application, 2, :accepted, :eligible_for_funded_place, funded_place: true) }
    let(:rows) { CSV.parse(csv, headers: true) }
    let(:first_application) { applications.first }
    let(:first_row) { rows.first.to_hash.symbolize_keys }

    it { expect(rows.count).to eq(applications.count) }
    it { expect(first_row.values).to all(be_present) }

    it "returns expected data", :aggregate_failures do
      expect(first_row).to include({
        participant_id: first_application.user.ecf_id,
        course_identifier: first_application.course.identifier,
        schedule_identifier: first_application.schedule.identifier,
        cohort: first_application.cohort.start_year.to_s,
        npq_application_id: first_application.ecf_id,
        eligible_for_funding: first_application.eligible_for_funding.to_s,
        training_status: first_application.training_status,
        school_urn: first_application.school.urn,
        funded_place: first_application.funded_place.to_s,
      })
    end

    context "when the schedule is nil" do
      before { first_application.update!(schedule: nil) }

      it { expect(first_row[:schedule_identifier]).to be_nil }
    end
  end
end
