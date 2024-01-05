module Migration::Ecf
  class School < Migration::Ecf::BaseRecord
    has_many :npq_applications, foreign_key: "school_urn", class_name: "Migration::Ecf::NpqApplication"
  end
end
