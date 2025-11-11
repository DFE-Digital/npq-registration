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

  def run!
    result = {}

    return result unless valid?

    ActiveRecord::Base.transaction do
      CSV.parse(file.download, headers: true).each_slice(1000) do |csv_rows|
        processed_ids = []
        ids_to_process = csv_rows.map { |row| row[FILE_HEADER_DECLARATION_ID] }

        Declaration
          .where(ecf_id: ids_to_process)
          .includes(:delivery_partner, :secondary_delivery_partner).find_each do |declaration|
          csv_row = csv_rows.select { |row| row[FILE_HEADER_DECLARATION_ID] == declaration.ecf_id }.first
          result[declaration.ecf_id] = process_declaration(declaration, csv_row[FILE_HEADER_DELIVERY_PARTNER_ID], csv_row[FILE_HEADER_SECONDARY_DELIVERY_PARTNER_ID])
          processed_ids << declaration.ecf_id
        end

        (ids_to_process - processed_ids).each do |missing_id|
          result[missing_id] = "Declaration not found"
        end
      end

      update!(result: result.to_json, finished_at: Time.zone.now)
    end

    result
  end

private

  def process_declaration(declaration, csv_delivery_partner_id, csv_secondary_delivery_partner_id)
    return "Declaration not found" unless declaration

    existing_delivery_partner = declaration.delivery_partner
    existing_secondary_delivery_partner = declaration.secondary_delivery_partner
    new_secondary_delivery_partner_id = csv_secondary_delivery_partner_id unless csv_secondary_delivery_partner_id == "#N/A"

    return "Declaration already has delivery partner" if new_secondary_delivery_partner_id.nil? && existing_delivery_partner
    return "Declaration already has secondary delivery partner" if existing_secondary_delivery_partner && new_secondary_delivery_partner_id

    if existing_delivery_partner
      delivery_partner = existing_delivery_partner
    else
      new_delivery_partner = DeliveryPartner.where(ecf_id: csv_delivery_partner_id).first
      return "Primary Delivery Partner not found: ID:#{csv_delivery_partner_id}" unless new_delivery_partner

      delivery_partner = new_delivery_partner
    end

    if new_secondary_delivery_partner_id
      new_secondary_delivery_partner = DeliveryPartner.where(ecf_id: new_secondary_delivery_partner_id).first
      return "Secondary Delivery Partner not found: ID:#{new_secondary_delivery_partner_id}" unless new_secondary_delivery_partner

      secondary_delivery_partner = new_secondary_delivery_partner
    end

    change_delivery_partner(declaration, delivery_partner, secondary_delivery_partner)
  end

  def change_delivery_partner(declaration, delivery_partner, secondary_delivery_partner)
    success = declaration.update(delivery_partner:, secondary_delivery_partner:)
    outcome(success, declaration.errors)
  end

  def outcome(success, errors)
    return "Declaration updated" if success

    errors.messages.values.flatten.to_sentence
  end
end
