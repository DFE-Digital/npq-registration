# frozen_string_literal: true

require "csv"

class AssuranceReports::CsvSerializer
  def initialize(scope, statement)
    self.scope = scope
    self.statement = statement
  end

  def filename
    "NPQ-Declarations-#{npq_lead_provider.name.gsub(/\W/, '')}-Cohort#{statement.cohort.start_year}-#{statement.name.gsub(/\W/, '')}.csv"
  end

  def serialize
    CSV.generate do |csv|
      csv << csv_headers

      scope.each do |record|
        csv << to_row(record)
      end
    end
  end

  def csv_headers
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
    ].compact
  end

private

  attr_accessor :scope, :statement

  def to_row(record)
    [
      record.participant_id,
      record.participant_name,
      record.trn,
      record.application_course_identifier,
      record.schedule,
      record.eligible_for_funding,
      record.funded_place,
      record.npq_lead_provider_name,
      record.school_urn,
      record.school_name,
      record.training_status,
      record.training_status_reason,
      record.declaration_id,
      record.declaration_status,
      record.declaration_type,
      record.declaration_date.iso8601,
      record.declaration_created_at.iso8601,
      format_statement_name(statement.month, statement.year),
      record.statement_id,
      record.targeted_delivery_funding,
    ]
  end

  def npq_lead_provider
    statement.npq_lead_provider
  end

  def format_statement_name(month, year)
    date = Date.new(year, month)
    date.strftime("%B %Y")
  end
end
