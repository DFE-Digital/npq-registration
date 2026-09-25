module ScrubPersonalData
  # Removes NINo and date of birth from the raw_application_data in the Application versions.
  #
  # object stores the values of the record, e.g. { "raw_application_data": { "date_of_birth": "1980-01-01" } }
  # object_changes stores [before, after] values, e.g. { "raw_application_data": [null, { "date_of_birth": "1980-01-01" }] }
  class ApplicationVersionsJob < BaseJob
  private

    def scrub_sql
      <<~SQL
        UPDATE versions
        SET
          object = jsonb_set(jsonb_set(object::jsonb,
            '{raw_application_data,national_insurance_number}', '"[REDACTED]"', false),
            '{raw_application_data,date_of_birth}', '"[REDACTED]"', false
          )::json,
          object_changes = jsonb_set(jsonb_set(jsonb_set(jsonb_set(object_changes::jsonb,
            '{raw_application_data,0,national_insurance_number}', '"[REDACTED]"', false),
            '{raw_application_data,0,date_of_birth}', '"[REDACTED]"', false),
            '{raw_application_data,1,national_insurance_number}', '"[REDACTED]"', false),
            '{raw_application_data,1,date_of_birth}', '"[REDACTED]"', false
          )::json
        WHERE id IN (
          SELECT id
          FROM versions
          WHERE item_type = 'Application'
            AND (
              object::jsonb #>> '{raw_application_data,national_insurance_number}' <> '[REDACTED]'
              OR object::jsonb #>> '{raw_application_data,date_of_birth}' <> '[REDACTED]'
              OR object_changes::jsonb #>> '{raw_application_data,0,national_insurance_number}' <> '[REDACTED]'
              OR object_changes::jsonb #>> '{raw_application_data,0,date_of_birth}' <> '[REDACTED]'
              OR object_changes::jsonb #>> '{raw_application_data,1,national_insurance_number}' <> '[REDACTED]'
              OR object_changes::jsonb #>> '{raw_application_data,1,date_of_birth}' <> '[REDACTED]'
            )
          ORDER BY id
          LIMIT #{BATCH_SIZE}
        )
      SQL
    end
  end
end
