class BulkOperation::SubmitDeclarations < BulkOperation
  HEADERS = true
  FILE_HEADERS = %w[participant_id declaration_type declaration_date course_identifier delivery_partner_id lead_provider_name has_passed].freeze

  def run!
    result = {}
    ActiveRecord::Base.transaction do
      result = csv_rows.each_with_index.to_h do |row, index|
        row_number = index + 1
        [row_number, process_csv_row(row)]
      end
      update!(result: result.to_json, finished_at: Time.zone.now)
    end

    result
  end

private

  def check_format
    csv = CSV.read(attached_file, headers: true)

    errors.add(:file, :empty) if csv.count.zero?

    if csv.headers != FILE_HEADERS
      errors.add(:file, :invalid)
    end
  rescue CSV::MalformedCSVError
    errors.add(:file, :malformed)
  end

  def csv_rows
    file.open { CSV.read(_1, headers: true) }
  end

  def process_csv_row(row)
    participant = User.find_by(ecf_id: row["participant_id"])
    return "Participant not found" if participant.nil?

    lead_provider = LeadProvider.find_by(name: row["lead_provider_name"])
    return "Lead provider not found" if lead_provider.nil?

    service = Declarations::Create.new(
      lead_provider: lead_provider,
      participant_id: row["participant_id"],
      declaration_type: row["declaration_type"],
      declaration_date: row["declaration_date"],
      course_identifier: row["course_identifier"],
      delivery_partner_id: row["delivery_partner_id"],
      has_passed: row["has_passed"].presence.try(:downcase),
    )

    if service.create_declaration
      "Declaration created successfully"
    else
      service.errors.full_messages.join(", ")
    end
  end
end
