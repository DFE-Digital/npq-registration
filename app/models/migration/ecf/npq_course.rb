module Migration::Ecf
  class NpqCourse < Migration::Ecf::BaseRecord
    has_many :npq_applications
  end
end
