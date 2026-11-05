module ScrubPersonalData
  # Removes NINo, date of birth and raw TRA provider data from the User versions.
  #
  # object field stores the values of the record, e.g. { "date_of_birth": "1980-01-01" }
  # object_changes field stores [before, after] values, e.g. { "date_of_birth": [null, "1980-01-01"] }
  class UserVersionsJob < BaseJob
  private

    def scrub_sql(batch_size)
      <<~SQL
        UPDATE versions
        SET
          object = jsonb_set(
            jsonb_set(
              jsonb_set(
                object::jsonb,
                '{national_insurance_number}',
                CASE WHEN object::jsonb ->> 'national_insurance_number' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                     ELSE COALESCE(object::jsonb -> 'national_insurance_number', 'null')
                END,
                false
              ),
              '{date_of_birth}',
              CASE WHEN object::jsonb ->> 'date_of_birth' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                   ELSE COALESCE(object::jsonb -> 'date_of_birth', 'null')
              END,
              false
            ),
            '{raw_tra_provider_data}',
            CASE WHEN object::jsonb ->> 'raw_tra_provider_data' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                 ELSE COALESCE(object::jsonb -> 'raw_tra_provider_data', 'null')
            END,
            false
          )::json,
          object_changes = jsonb_set(
            jsonb_set(
              jsonb_set(
                jsonb_set(
                  jsonb_set(
                    jsonb_set(
                      object_changes::jsonb,
                      '{national_insurance_number,0}',
                      CASE WHEN object_changes::jsonb #>> '{national_insurance_number,0}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                           ELSE COALESCE(object_changes::jsonb #> '{national_insurance_number,0}', 'null')
                      END,
                      false
                    ),
                    '{national_insurance_number,1}',
                    CASE WHEN object_changes::jsonb #>> '{national_insurance_number,1}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                         ELSE COALESCE(object_changes::jsonb #> '{national_insurance_number,1}', 'null')
                    END,
                    false
                  ),
                  '{date_of_birth,0}',
                  CASE WHEN object_changes::jsonb #>> '{date_of_birth,0}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                       ELSE COALESCE(object_changes::jsonb #> '{date_of_birth,0}', 'null')
                  END,
                  false
                ),
                '{date_of_birth,1}',
                CASE WHEN object_changes::jsonb #>> '{date_of_birth,1}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                     ELSE COALESCE(object_changes::jsonb #> '{date_of_birth,1}', 'null')
                END,
                false
              ),
              '{raw_tra_provider_data,0}',
              CASE WHEN object_changes::jsonb #>> '{raw_tra_provider_data,0}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                   ELSE COALESCE(object_changes::jsonb #> '{raw_tra_provider_data,0}', 'null')
              END,
              false
            ),
            '{raw_tra_provider_data,1}',
            CASE WHEN object_changes::jsonb #>> '{raw_tra_provider_data,1}' NOT IN ('[REDACTED]', '') THEN '"[REDACTED]"'
                 ELSE COALESCE(object_changes::jsonb #> '{raw_tra_provider_data,1}', 'null')
            END,
            false
          )::json
        WHERE id IN (
          SELECT id
          FROM versions
          WHERE item_type = 'User'
            AND (
              object::jsonb ->> 'national_insurance_number' NOT IN ('[REDACTED]', '')
              OR object::jsonb ->> 'date_of_birth' NOT IN ('[REDACTED]', '')
              OR object::jsonb ->> 'raw_tra_provider_data' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{national_insurance_number,0}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{national_insurance_number,1}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{date_of_birth,0}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{date_of_birth,1}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{raw_tra_provider_data,0}' NOT IN ('[REDACTED]', '')
              OR object_changes::jsonb #>> '{raw_tra_provider_data,1}' NOT IN ('[REDACTED]', '')
            )
          ORDER BY id
          LIMIT #{batch_size}
        )
      SQL
    end
  end
end
