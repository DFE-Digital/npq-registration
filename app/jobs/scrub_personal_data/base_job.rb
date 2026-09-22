module ScrubPersonalData
  # Base class for the jobs that remove personal data (NINo, date of birth, etc.)
  # from old records.
  #
  # Each run scrubs at most BATCH_SIZE records, so we do not put too much load on
  # the database. If it scrubbed anything, it schedules itself to run again after
  # RERUN_AFTER. If the last run finds nothing to scrub, it stops.
  class BaseJob < ApplicationJob
    BATCH_SIZE = 5_000
    RERUN_AFTER = 30.minutes

    queue_as :low_priority

    def perform
      count = ActiveRecord::Base.connection.exec_update(scrub_sql)

      self.class.set(wait: RERUN_AFTER).perform_later if count.positive?
    end

  private

    # SQL that scrubs the next BATCH_SIZE records.
    def scrub_sql
      raise NotImplementedError
    end
  end
end
