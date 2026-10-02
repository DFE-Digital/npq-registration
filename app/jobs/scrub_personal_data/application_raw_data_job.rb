module ScrubPersonalData
  # Removes NINo and date of birth from Application#raw_application_data.
  class ApplicationRawDataJob < BaseJob
  private

    def scrub_sql
      <<~SQL
        UPDATE applications
        SET
          raw_application_data = jsonb_set(jsonb_set(raw_application_data,
            '{national_insurance_number}', '"[REDACTED]"', false),
            '{date_of_birth}', '"[REDACTED]"', false
          )
        WHERE id IN (
          SELECT id
          FROM applications
          WHERE raw_application_data ->> 'national_insurance_number' <> '[REDACTED]'
            OR raw_application_data ->> 'date_of_birth' <> '[REDACTED]'
          ORDER BY id
          LIMIT #{BATCH_SIZE}
        )
      SQL
    end
  end
end
