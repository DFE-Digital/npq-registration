class BulkOperation::BackfillDeclarationDeliveryPartners < BulkOperation
  HEADERS = true
  FILE_HEADER_DECLARATION_ID = "Declaration ID".freeze
  FILE_HEADER_DELIVERY_PARTNER_ID = "Primary Delivery Partner ID".freeze
  FILE_HEADER_SECONDARY_DELIVERY_PARTNER_ID = "Secondary Delivery Partner ID".freeze
  FILE_HEADERS = [
    FILE_HEADER_DECLARATION_ID,
    FILE_HEADER_DELIVERY_PARTNER_ID,
    FILE_HEADER_SECONDARY_DELIVERY_PARTNER_ID,
  ].freeze

  def ids_to_update
    file.open { CSV.read(_1, headers: true) }
  end

  def run!
    result = {}

    return result unless valid?

    ActiveRecord::Base.transaction do
      result = ids_to_update.each_with_object({}) do |csv_row, outcomes_hash|
        outcomes_hash[declaration_ecf_id(csv_row)] = process_csv_row(csv_row)
      end
      update!(result: result.to_json, finished_at: Time.zone.now)
    end

    result
  end

private

  def process_csv_row(csv_row)
    declaration = Declaration.find_by(ecf_id: declaration_ecf_id(csv_row))
    return "Declaration not found" unless declaration

    existing_delivery_partner = declaration.delivery_partner
    existing_secondary_delivery_partner = declaration.secondary_delivery_partner
    delivery_partner_id = csv_row[FILE_HEADER_DELIVERY_PARTNER_ID]
    secondary_delivery_partner_id = csv_row[FILE_HEADER_SECONDARY_DELIVERY_PARTNER_ID]
    secondary_delivery_partner_id = nil if secondary_delivery_partner_id == "#N/A"

    new_delivery_partner_id = existing_delivery_partner ? existing_delivery_partner.ecf_id : delivery_partner_id
    new_secondary_delivery_partner_id =
      existing_secondary_delivery_partner ? existing_secondary_delivery_partner.ecf_id : secondary_delivery_partner_id

    unless DeliveryPartner.exists?(ecf_id: new_delivery_partner_id)
      return "Primary Delivery Partner not found: ID:#{new_delivery_partner_id}"
    end

    if new_secondary_delivery_partner_id
      unless DeliveryPartner.exists?(ecf_id: new_secondary_delivery_partner_id)
        return "Secondary Delivery Partner not found: ID:#{new_secondary_delivery_partner_id}"
      end

      if existing_secondary_delivery_partner && new_secondary_delivery_partner_id == existing_secondary_delivery_partner.ecf_id
        return "Declaration already has secondary delivery partner"
      end
    elsif new_delivery_partner_id == existing_delivery_partner&.ecf_id
      return "Declaration already has delivery partner"
    end

    change_delivery_partner = Declarations::ChangeDeliveryPartner.new(
      declaration:,
      delivery_partner_id: new_delivery_partner_id,
      secondary_delivery_partner_id: new_secondary_delivery_partner_id,
    )

    success = change_delivery_partner.change_delivery_partner
    outcome(success, change_delivery_partner.errors)
  end

  def outcome(success, errors)
    return "Declaration updated" if success

    errors.messages.values.flatten.to_sentence
  end

  def declaration_ecf_id(csv_row)
    csv_row[FILE_HEADER_DECLARATION_ID]
  end
end
