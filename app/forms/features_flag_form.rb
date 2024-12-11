class FeaturesFlagForm
    include ActiveModel::Model

    attr_accessor :feature_flag_name

    validates :feature_flag_name,  presence: true

    validate :matching_flag_name

    def matching_flag_name
        if feature_flag_name.present?
            if feature_flag_name != feature_id
                errors.add(:feature_flag_name, :name_does_not_match)
            end
        end
    end
end