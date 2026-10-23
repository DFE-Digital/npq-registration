module ScrubPersonalData
  # Removes NINo and date of birth from the raw_application_data in the Application versions.
  #
  # object field stores the values of the record, e.g. { "raw_application_data": { "date_of_birth": "1980-01-01" } }
  # object_changes field stores [before, after] values, e.g. { "raw_application_data": [null, { "date_of_birth": "1980-01-01" }] }
  class ApplicationVersionsJob < BaseJob
  private

    def scrub_sql(batch_size)
      <<~SQL
        UPDATE versions
        SET
          object = jsonb_set(
            jsonb_set(
              object::jsonb,
              '{raw_application_data,national_insurance_number}',
              CASE WHEN object::jsonb #>> '{raw_application_data,national_insurance_number}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                   ELSE COALESCE(object::jsonb #> '{raw_application_data,national_insurance_number}', 'null')
              END,
              false
            ),
            '{raw_application_data,date_of_birth}',
            CASE WHEN object::jsonb #>> '{raw_application_data,date_of_birth}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                 ELSE COALESCE(object::jsonb #> '{raw_application_data,date_of_birth}', 'null')
            END,
            false
          )::json,
          object_changes = jsonb_set(
            jsonb_set(
              jsonb_set(
                jsonb_set(
                  object_changes::jsonb,
                  '{raw_application_data,0,national_insurance_number}',
                  CASE WHEN object_changes::jsonb #>> '{raw_application_data,0,national_insurance_number}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                       ELSE COALESCE(object_changes::jsonb #> '{raw_application_data,0,national_insurance_number}', 'null')
                  END,
                  false
                ),
                '{raw_application_data,0,date_of_birth}',
                CASE WHEN object_changes::jsonb #>> '{raw_application_data,0,date_of_birth}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                     ELSE COALESCE(object_changes::jsonb #> '{raw_application_data,0,date_of_birth}', 'null')
                END,
                false
              ),
              '{raw_application_data,1,national_insurance_number}',
              CASE WHEN object_changes::jsonb #>> '{raw_application_data,1,national_insurance_number}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                   ELSE COALESCE(object_changes::jsonb #> '{raw_application_data,1,national_insurance_number}', 'null')
              END,
              false
            ),
            '{raw_application_data,1,date_of_birth}',
            CASE WHEN object_changes::jsonb #>> '{raw_application_data,1,date_of_birth}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                 ELSE COALESCE(object_changes::jsonb #> '{raw_application_data,1,date_of_birth}', 'null')
            END,
            false
          )::json
        WHERE id IN (
          SELECT id
          FROM versions
          WHERE item_type = 'Application'
            AND (
              object::jsonb #>> '{raw_application_data,national_insurance_number}' NOT IN ('[REDACTED]', '')
              OR object::jsonb #>> '{raw_application_data,date_of_birth}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{raw_application_data,0,national_insurance_number}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{raw_application_data,0,date_of_birth}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{raw_application_data,1,national_insurance_number}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{raw_application_data,1,date_of_birth}' NOT IN ('[REDACTED]', '')
            )
          ORDER BY id
          LIMIT #{batch_size}
        )
      SQL
    end
  end
end
