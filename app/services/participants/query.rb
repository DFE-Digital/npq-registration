module Participants
  class Query
    include API::Concerns::Orderable
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider: :ignore, updated_since: :ignore, training_status: :ignore, from_participant_id: :ignore, sort: nil)
      @scope = all_participants
      @sort = sort

      where_lead_provider_is(lead_provider)
      where_updated_since(updated_since)
      where_training_status_is(training_status)
      where_from_participant_id_is(from_participant_id)
    end

    def participants
      scope.order(order_by)
    end

    def participant(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      scope.merge!(Application.where(lead_provider:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(User.where(updated_at: updated_since..))
    end

    def where_training_status_is(training_status)
      return if ignore?(filter: training_status)
      return unless Application.training_statuses[training_status]

      scope.merge!(Application.where(training_status:))
    end

    def where_from_participant_id_is(from_participant_id)
      return if ignore?(filter: from_participant_id)

      scope.merge!(scope.joins(:participant_id_changes).merge(ParticipantIdChange.where(from_participant: User.where(ecf_id: from_participant_id))))
    end

    def order_by
      sort_order(sort:, model: User, default: { created_at: :asc })
    end

    def all_participants
      User
        .joins(:applications).merge(Application.accepted)
        .includes(
          :participant_id_changes,
          applications: %i[
            course
            school
            cohort
            lead_provider
            application_states
            schedule
          ],
        )
    end
  end
end
