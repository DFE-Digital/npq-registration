module ScrubPersonalData
  # Removes NINo and date of birth from Application#raw_application_data.
  class ApplicationRawDataJob < BaseJob
  private

    def scrub_sql(batch_size)
      <<~SQL
        UPDATE applications
        SET
          raw_application_data = jsonb_set(
            jsonb_set(
              raw_application_data,
              '{national_insurance_number}',
              CASE WHEN raw_application_data ->> 'national_insurance_number' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                   ELSE COALESCE(raw_application_data -> 'national_insurance_number', 'null')
              END,
              false
            ),
            '{date_of_birth}',
            CASE WHEN raw_application_data ->> 'date_of_birth' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                 ELSE COALESCE(raw_application_data -> 'date_of_birth', 'null')
            END,
            false
          )
        WHERE id IN (
          SELECT id
          FROM applications
          WHERE raw_application_data ->> 'national_insurance_number' NOT IN ('[REDACTED]', '')
            OR raw_application_data ->> 'date_of_birth' NOT IN ('[REDACTED]', '')
          ORDER BY id
          LIMIT #{batch_size}
        )
      SQL
    end
  end
end
