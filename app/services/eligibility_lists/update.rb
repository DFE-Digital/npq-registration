module EligibilityLists
  class Update
    include ActiveModel::Validations
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :eligibility_list_type
    attribute :file

    def call
      identifier_type = if eligibility_list_type == "pp50_further_education"
                          "ukprn"
                        else
                          "urn"
                        end
      rows = CSV.table(file)
      ActiveRecord::Base.transaction do
        EligibilityList.where(eligibility_list_type:).delete_all
        rows.each do |row|
          EligibilityList.create!(identifier: row[identifier_type.to_sym], eligibility_list_type:, identifier_type:)
        end
      end

      true
    end
  end
end
