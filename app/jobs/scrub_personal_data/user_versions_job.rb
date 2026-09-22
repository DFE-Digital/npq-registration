module ScrubPersonalData
  # Removes NINo, date of birth and raw TRA provider data from the User versions.
  #
  # object stores the values of the record, e.g. { "date_of_birth": "1980-01-01" }
  # object_changes stores [before, after] values, e.g. { "date_of_birth": [null, "1980-01-01"] }
  class UserVersionsJob < BaseJob
  private

    def scrub_sql
      <<~SQL
        UPDATE versions
        SET
          object = jsonb_set(jsonb_set(jsonb_set(object::jsonb,
            '{national_insurance_number}', '"[REDACTED]"', false),
            '{date_of_birth}', '"[REDACTED]"', false),
            '{raw_tra_provider_data}', '"[REDACTED]"', false
          )::json,
          object_changes = jsonb_set(jsonb_set(jsonb_set(object_changes::jsonb,
            '{national_insurance_number}', '["[REDACTED]", "[REDACTED]"]', false),
            '{date_of_birth}', '["[REDACTED]", "[REDACTED]"]', false),
            '{raw_tra_provider_data}', '["[REDACTED]", "[REDACTED]"]', false
          )::json
        WHERE id IN (
          SELECT id
          FROM versions
          WHERE item_type = 'User'
            AND (
              object::jsonb ->> 'national_insurance_number' <> '[REDACTED]'
              OR object::jsonb ->> 'date_of_birth' <> '[REDACTED]'
              OR object::jsonb ->> 'raw_tra_provider_data' <> '[REDACTED]'
              OR object_changes::jsonb -> 'national_insurance_number' <> '["[REDACTED]", "[REDACTED]"]'
              OR object_changes::jsonb -> 'date_of_birth' <> '["[REDACTED]", "[REDACTED]"]'
              OR object_changes::jsonb -> 'raw_tra_provider_data' <> '["[REDACTED]", "[REDACTED]"]'
            )
          ORDER BY id
          LIMIT #{BATCH_SIZE}
        )
      SQL
    end
  end
end
