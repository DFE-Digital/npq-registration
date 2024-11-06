module Migration::Ecf
  class NpqApplication < BaseRecord
    belongs_to :participant_identity
    belongs_to :npq_lead_provider
    belongs_to :npq_course
    belongs_to :cohort, optional: true
    has_one :profile, class_name: "ParticipantProfile", foreign_key: :id
    has_one :user, through: :participant_identity
    has_one :school, class_name: "School", foreign_key: :urn, primary_key: :school_urn

    def ineligible_for_funding_reason
      if previously_funded?
        return "previously-funded"
      end

      unless eligible_for_funding
        "establishment-ineligible"
      end
    end

  private

    def previously_funded?
      @previously_funded ||= participant_identity
        .npq_applications
        .where.not(id:)
        .where(npq_course: npq_course.rebranded_alternative_courses)
        .where(eligible_for_funding: true)
        .where(funded_place: [nil, true])
        .where(lead_provider_approval_status: "accepted")
        .exists?
    end
  end
end
