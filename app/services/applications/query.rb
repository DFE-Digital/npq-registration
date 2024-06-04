module Applications
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats

    attr_reader :scope, :sort

    def initialize(lead_provider: :ignore, cohort_start_years: :ignore, updated_since: :ignore, lead_provider_approval_status: :ignore, participant_ids: :ignore, sort: nil)
      # The subquery is an optimization so that we don't have to perform
      # a separate query for each record as part of Application#previously_funded?
      @scope = all_applications.select(
        "applications.*",
        "EXISTS(
          WITH json_data(alt_courses) AS (VALUES ('#{ActiveRecord::Base.sanitize_sql(alternative_courses)}'::jsonb))
          SELECT 1 AS one FROM applications AS a, json_data
            WHERE a.id != applications.id AND
                  a.user_id = applications.user_id AND
                  a.eligible_for_funding = true AND
                  a.lead_provider_approval_status = 'accepted' AND
                  a.course_id IN (
                    SELECT jsonb_array_elements_text(alt_courses->(applications.course_id::text))::bigint
                    FROM json_data
                  )
            LIMIT 1
        ) AS transient_previously_funded",
      )
      @sort = sort

      where_lead_provider_approval_status_in(lead_provider_approval_status)
      where_lead_provider_is(lead_provider)
      where_cohort_start_year_in(cohort_start_years)
      where_updated_since(updated_since)
      where_participant_ids_in(participant_ids)
    end

    def applications
      scope.order(order_by)
    end

    def application(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    def where_lead_provider_approval_status_in(lead_provider_approval_status)
      return if lead_provider_approval_status == :ignore

      scope.merge!(Application.where(lead_provider_approval_status: extract_conditions(lead_provider_approval_status, allowlist: Application.lead_provider_approval_statuses.values)))
    end

    def where_lead_provider_is(lead_provider)
      return if lead_provider == :ignore

      scope.merge!(Application.where(lead_provider:))
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if cohort_start_years == :ignore

      scope.merge!(Application.where(cohort: { start_year: extract_conditions(cohort_start_years) }))
    end

    def where_updated_since(updated_since)
      return if updated_since == :ignore

      scope.merge!(Application.where(updated_at: updated_since..))
    end

    def where_participant_ids_in(participant_ids)
      return if participant_ids == :ignore

      scope.merge!(Application.where(user: { ecf_id: extract_conditions(participant_ids) }))
    end

    def order_by
      sort_order(sort:, model: Application, default: { created_at: :asc })
    end

    def alternative_courses
      Course
        .all
        .each_with_object({}) { |c, h| h[c.id] = c.rebranded_alternative_courses.map(&:id) }
        .to_json
    end

    def all_applications
      Application
        .includes(
          :course,
          :user,
          :school,
          :cohort,
          :private_childcare_provider,
          :itt_provider,
          :schedule,
        )
    end
  end
end
