module Migration::Ecf
  class NpqCourse < BaseRecord
    has_many :npq_applications
  end
end
