module EligibilityLists
  class Update
    include ActiveModel::Validations
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :eligibility_list_type
    attribute :file

    validates :file, presence: true
    validate :headers_valid

    def call
      return unless valid?

      rows = CSV.table(file)
      ActiveRecord::Base.transaction do
        eligibility_list_type.constantize.delete_all
        rows.each do |row|
          eligibility_list_type.constantize.create!(identifier: row[eligibility_list_type.constantize::IDENTIFIER_TYPE])
        end
      end

      rows.count
    end

  private

    def headers_valid
      return if errors.any?

      actual_headers = CSV.table(file).headers
      errors.add(:file, :invalid_headers) unless actual_headers.include?(eligibility_list_type.constantize::IDENTIFIER_TYPE)
    end
  end
end
