module Migration::Ecf
  class Cohort < BaseRecord
    has_many :statements
  end
end
