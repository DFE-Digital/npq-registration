module ScrubPersonalData
  # Base class for the jobs that remove personal data (NINo, date of birth, etc.)
  # from old records.
  #
  # Each run scrubs at most batch_size records, so we do not put too much load on
  # the database.
  #
  # With reschedule, if it scrubbed anything, it runs itself again
  # after RERUN_AFTER. If the last run finds nothing to scrub, it stops.
  # It does not reschedule by default.
  class BaseJob < ApplicationJob
    BATCH_SIZE = 5_000
    RERUN_AFTER = 30.minutes

    queue_as :low_priority

    def perform(batch_size: BATCH_SIZE, reschedule: false)
      count = ActiveRecord::Base.connection.exec_update(scrub_sql(Integer(batch_size)))

      self.class.set(wait: RERUN_AFTER).perform_later(batch_size:, reschedule:) if reschedule && count.positive?
    end

  private

    # SQL that scrubs the next batch_size records.
    def scrub_sql(_batch_size)
      raise NotImplementedError
    end
  end
end
