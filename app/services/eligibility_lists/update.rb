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
        EligibilityList.where(eligibility_list_type:).delete_all
        rows.each do |row|
          EligibilityList.create!(identifier: row[identifier_type.to_sym], eligibility_list_type:, identifier_type:)
        end
      end

      rows.count
    end

  private

    def identifier_type
      if eligibility_list_type == "pp50_further_education"
        :ukprn
      else
        :urn
      end
    end

    def headers_valid
      return if errors.any?

      actual_headers = CSV.table(file).headers
      errors.add(:file, :invalid_headers) unless actual_headers.include?(identifier_type)
    end
  end
end
