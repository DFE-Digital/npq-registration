module Migration::Ecf
  class BaseRecord < ApplicationRecord
    self.abstract_class = true

    connects_to database: { reading: :ecf, writing: :ecf } unless Rails.env.review?

    def readonly?
      # Not to be readonly in test so we can create factories
      !Rails.env.test?
    end
  end
end
