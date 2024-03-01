module Migration::Ecf
  class Cohort < BaseRecord
    has_many :statements, class_name: "Finance::Statement"
  end
end
