module Migration::Ecf
  class TeacherProfile < Migration::Ecf::BaseRecord
    belongs_to :user
  end
end
