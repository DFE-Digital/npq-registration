json.data do
  json.array! @participants do |participant|
    json.id participant.id
    json.type "npq-participant"
    json.attributes do
      json.full_name participant.full_name
      json.teacher_reference_number participant.teacher_reference_number
      json.updated_at participant.updated_at
      json.npq_enrolments do
        json.array! participant.npq_enrolments do |enrolment|
          json.email enrolment.email
          json.course_identifier enrolment.course_identifier
          json.schedule_identifier enrolment.schedule_identifier
          json.cohort enrolment.cohort
          json.npq_application_id enrolment.npq_application_id
          json.eligible_for_funding enrolment.eligible_for_funding
          json.training_status enrolment.training_status
          json.school_urn enrolment.school_urn
          json.targeted_delivery_funding_eligibility enrolment.targeted_delivery_funding_eligibility
          json.withdrawal enrolment.withdrawal
          json.deferral enrolment.deferral
          json.created_at enrolment.created_at
        end
      end
      json.participant_id_changes do
        json.array! participant.participant_id_changes do |change|
          json.from_participant_id change.from_participant_id
          json.to_participant_id change.to_participant_id
          json.changed_at change.changed_at
        end
      end
    end
  end
end
