module Qualifications
  class Query
    delegate :connection, :sanitize_sql, to: ApplicationRecord

    def qualifications(trn:)
      sql = sanitize_sql([query, { trn: }])
      connection.execute(sql).to_a
    end

  private

    def query
      <<-SQL
        SELECT award_date, npq_type FROM (#{participant_outcomes_query}) current
        UNION
        SELECT award_date, npq_type FROM (#{legacy_outcomes_query}) legacy
        ORDER BY award_date DESC
      SQL
    end

    def participant_outcomes_query
      <<~SQL
        SELECT
          participant_outcomes.completion_date award_date,
          courses.short_code npq_type
        FROM users
        JOIN applications ON users.id = applications.user_id
        JOIN declarations ON applications.id = declarations.application_id
        JOIN participant_outcomes ON declarations.id = participant_outcomes.declaration_id
        JOIN courses ON applications.course_id = courses.id
        WHERE participant_outcomes.state = 'passed'
        AND users.trn = :trn
      SQL
    end

    def legacy_outcomes_query
      <<~SQL
        SELECT
          completion_date award_date,
          course_short_code npq_type
        FROM legacy_passed_participant_outcomes
        WHERE trn = :trn
      SQL
    end
  end
end
