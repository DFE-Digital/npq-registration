module Migration::Ecf
  class NpqLeadProvider < Migration::Ecf::BaseRecord
    has_many :npq_applications
  end
end
