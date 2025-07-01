module API
  class ParticipantIdChangeSerializer < Blueprinter::Base
    field(:from_participant_id)
    field(:to_participant_id)
    field(:changed_at) { |object| object.created_at.rfc3339 }
  end
end
