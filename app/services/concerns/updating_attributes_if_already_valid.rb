module UpdatingAttributesIfAlreadyValid
  extend ActiveSupport::Concern

  included do
    def update_attributes_if_already_valid(model_attribute, attributes)
      return false if invalid?

      model_attribute.assign_attributes(attributes)

      model_attribute.save # rubocop:disable Rails/SaveBang - return value is used by caller
    end
  end
end
