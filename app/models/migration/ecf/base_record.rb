module Migration::Ecf
  class BaseRecord < ApplicationRecord
    self.abstract_class = true

    connects_to database: { reading: :ecf, writing: :ecf } unless Rails.env.review?

    def readonly?
      true
    end
  end
end
