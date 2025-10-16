module EligibilityLists
  class Update
    include ActiveModel::Validations
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :eligibility_list_type
    attribute :file

    validates :file, presence: true
    validate :csv_valid
    validate :file_not_empty, if: -> { file.present? }

    def call
      return unless valid?

      ActiveRecord::Base.transaction do
        eligibility_list_type_class.delete_all
        csv_table.each do |row|
          eligibility_list_type_class.find_or_create_by!(identifier: identifier(row))
        end
      end

      csv_table.count
    end

  private

    def eligibility_list_type_class
      @eligibility_list_type_class ||= eligibility_list_type.constantize
    end

    def csv_table(iso_8859_1: false)
      @csv_table ||= if iso_8859_1
                       CSV.table(file, encoding: "ISO-8859-1", header_converters: ->(header) { header&.strip })
                     else
                       CSV.table(file, header_converters: ->(header) { header&.strip })
                     end
    end

    def csv_valid
      return if errors.any?

      all_headers_present = (eligibility_list_type_class::IDENTIFIER_CSV_HEADERS - csv_table.headers).empty?
      errors.add(:file, :invalid_headers) unless all_headers_present
    rescue CSV::MalformedCSVError => e
      if e.message.include?("Invalid byte sequence in UTF-8")
        csv_table(iso_8859_1: true)
        return if valid?
      end
      errors.add(:file, :invalid)
      errors.add(:base, message: e.message)
    end

    def file_not_empty
      return if errors.any?

      errors.add(:file, :empty) if csv_table.count.zero?
    end

    def identifier(row)
      if eligibility_list_type_class::IDENTIFIER_CSV_HEADERS.count > 1
        row[eligibility_list_type_class::IDENTIFIER_CSV_HEADERS.last].presence || row[eligibility_list_type_class::IDENTIFIER_CSV_HEADERS.first]
      else
        row[eligibility_list_type_class::IDENTIFIER_CSV_HEADERS.first]
      end
    end
  end
end
