require "qualified_teachers"

class SendToQualifiedTeachersAPIJob < ApplicationJob
  queue_as :participant_outcomes
  retry_on TooManyRequests, attempts: 3

  def perform(participant_outcome_id:)
    QualifiedTeachersAPISender.new(participant_outcome_id:).send_record
  end
end
