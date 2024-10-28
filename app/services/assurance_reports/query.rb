# frozen_string_literal: true

module AssuranceReports
  class Query
    def initialize(statement)
      self.statement = statement
    end

    def declarations
      Declaration.find_by_sql(sql)
    end

  private

    attr_accessor :statement

    def sql
      <<~EOSQL
        SELECT
          d.id                                    AS id,
          u.ecf_id                                AS participant_id,
          u.full_name                             AS participant_name,
          u.trn                                   AS trn,
          c.identifier                            AS application_course_identifier,
          sch.identifier                          AS schedule,
          a.eligible_for_funding                  AS eligible_for_funding,
          a.funded_place                          AS funded_place,
          lp.name                                 AS npq_lead_provider_name,
          lp.ecf_id                               AS npq_lead_provider_id,
          sc.urn                                  AS school_urn,
          sc.name                                 AS school_name,
          a.training_status                       AS training_status,
          st.reason                               AS training_status_reason,
          d.ecf_id                                AS declaration_id,
          si.state                                AS declaration_status,
          d.declaration_type                      AS declaration_type,
          d.declaration_date                      AS declaration_date,
          d.created_at                            AS declaration_created_at,
          s.ecf_id                                AS statement_id,
          s.month                                 AS statement_month,
          s.year                                  AS statement_year,
          a.targeted_delivery_funding_eligibility AS targeted_delivery_funding
        FROM declarations d
        JOIN statement_items si             ON si.declaration_id = d.id
        JOIN statements s                   ON s.id = si.statement_id
        JOIN lead_providers lp              ON lp.id = d.lead_provider_id
        JOIN applications a                 ON a.id = d.application_id
        JOIN courses c                      ON c.id = a.course_id
        JOIN users u                        ON u.id = a.user_id
        JOIN schedules sch                  ON sch.id = a.schedule_id
        LEFT OUTER JOIN schools sc          ON sc.id = a.school_id
        LEFT OUTER JOIN (
             SELECT DISTINCT ON (lead_provider_id, application_id) lead_provider_id, application_id, state, reason
             FROM application_states
             ORDER BY lead_provider_id, application_id, created_at DESC
        ) AS st ON
          st.application_id = a.id AND
          st.lead_provider_id = d.lead_provider_id AND
          st.state = 'withdrawn'
        WHERE #{where_values}
        ORDER BY u.full_name ASC
      EOSQL
    end

    def where_values
      Declaration.sanitize_sql_for_conditions(["lp.id = ? AND s.id = ?", statement.lead_provider_id, statement.id])
    end
  end
end
