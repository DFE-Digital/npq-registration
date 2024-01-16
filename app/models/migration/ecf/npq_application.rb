module Migration::Ecf
  class NpqApplication < Migration::Ecf::BaseRecord
    belongs_to :npq_course
    belongs_to :npq_lead_provider
    belongs_to :participant_identity
    delegate :user, to: :participant_identity
    has_one :school, class_name: "Migration::Ecf::School", foreign_key: :urn, primary_key: :school_urn

    alias_method :course, :npq_course
    alias_method :ecf_id, :id
  end
end
