module Migration::Ecf
  class NpqContract < BaseRecord
    belongs_to :npq_lead_provider
    belongs_to :cohort
    belongs_to :npq_course, primary_key: :identifier, foreign_key: :course_identifier
  end
end
