module EligibilityLists
  class Update
    include ActiveModel::Validations
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :eligibility_list_type
    attribute :file

    validates :file, presence: true
    validate :headers_valid
    validate :file_not_empty, if: -> { file.present? }

    def call
      return unless valid?

      ActiveRecord::Base.transaction do
        eligibility_list_type.constantize.delete_all
        csv_table.each do |row|
          eligibility_list_type.constantize.create!(identifier: row[eligibility_list_type.constantize::IDENTIFIER_HEADER])
        end
      end

      csv_table.count
    end

  private

    def csv_table
      @csv_table ||= CSV.table(file, header_converters: [])
    end

    def headers_valid
      return if errors.any?

      actual_headers = csv_table.headers
      errors.add(:file, :invalid_headers) unless actual_headers.include?(eligibility_list_type.constantize::IDENTIFIER_HEADER)
    end

    def file_not_empty
      return if errors.any?

      errors.add(:file, :empty) if csv_table.count.zero?
    end
  end
end
