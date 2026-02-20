module ModelAttributeUpdatable
  extend ActiveSupport::Concern

  included do
    def update_and_validate_attributes(model_attribute, attributes)
      # check main validations, and avoid attribute assignment if invalid
      return false if invalid?

      model_attribute.assign_attributes(attributes)

      # check model attribute validation
      return false if invalid?

      model_attribute.save # rubocop:disable Rails/SaveBang - return value is used by caller
    end
  end
end
