module Migration::Ecf
  class School < BaseRecord
    has_many :npq_applications, primary_key: :urn, foreign_key: :school_urn, class_name: "NpqApplication"
  end
end
