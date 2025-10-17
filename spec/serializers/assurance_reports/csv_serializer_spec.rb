# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssuranceReports::CsvSerializer, type: :serializer do
  subject(:instance) { described_class.new(data, statement) }

  before { declaration }

  let(:data)          { AssuranceReports::Query.new(statement).declarations }
  let(:lead_provider) { create(:lead_provider) }
  let(:statement)     { create(:statement, lead_provider:) }
  let(:application)   { create(:application, :eligible_for_funded_place, lead_provider:) }

  let :declaration do
    travel_to(statement.deadline_date) do
      create(:declaration, lead_provider:, application:) do |declaration|
        create(:statement_item, statement:, declaration:)
      end
    end
  end

  describe "#filename" do
    subject { instance.filename }

    it { is_expected.to match(%r{NPQ-Declarations-\w+-Cohort#{statement.cohort.name}-\w+\.csv}) }
  end

  describe "#serialize" do
    let(:rows) { CSV.parse(instance.serialize, headers: true).to_a }

    describe "header row" do
      subject { rows.first }

      let :expected_headers do
        [
          "Participant ID",
          "Participant Name",
          "TRN",
          "Course Identifier",
          "Schedule",
          "Eligible For Funding",
          "Funded place",
          "Lead Provider Name",
          "School Urn",
          "School Name",
          "Training Status",
          "Training Status Reason",
          "Declaration ID",
          "Declaration Status",
          "Declaration Type",
          "Declaration Date",
          "Declaration Created At",
          "Statement Name",
          "Statement ID",
          "Targeted Delivery Funding",
        ]
      end

      it { is_expected.to eq expected_headers }
    end

    describe "a data row" do
      subject { rows.second }

      let(:training_status)        { "active" }
      let(:training_status_reason) { nil }

      let :expected_data do
        [
          declaration.user.ecf_id,
          declaration.user.full_name,
          declaration.user.trn,
          declaration.course.identifier,
          declaration.application.schedule.identifier,
          declaration.application.eligible_for_funding.to_s,
          declaration.application.funded_place.to_s,
          lead_provider.name,
          declaration.application.school.urn,
          declaration.application.school.name,
          training_status,
          training_status_reason,
          declaration.ecf_id,
          statement.statement_items.first.state,
          declaration.declaration_type,
          declaration.declaration_date.iso8601,
          declaration.created_at.iso8601,
          Date.new(statement.year, statement.month).strftime("%B %Y"),
          statement.ecf_id,
          declaration.application.targeted_delivery_funding_eligibility.to_s,
        ]
      end

      it { is_expected.to eq expected_data }

      context "when withdrawn" do
        before do
          declaration.application.update! training_status: "withdrawn"

          create(:application_state, :withdrawn, application: declaration.application,
                                                 lead_provider: declaration.lead_provider)
        end

        let(:training_status)        { "withdrawn" }
        let(:training_status_reason) { "other" }

        it { is_expected.to eq expected_data }
      end

      context "when deferred" do
        before do
          declaration.application.update! training_status: "deferred"

          create(:application_state, :deferred, application: declaration.application,
                                                lead_provider: declaration.lead_provider)
        end

        let(:training_status) { "deferred" }

        it { is_expected.to eq expected_data }
      end
    end
  end
end
