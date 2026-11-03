class ApplicationJob < ActiveJob::Base
  # Custom backoff rate for retries
  #
  # Offset from first attempt
  # 6 seconds
  # 0 hours 1 minutes
  # 0 hours 13 minutes
  # 1 hours 21 minutes
  # 5 hours 42 minutes
  # 18 hours 40 minutes
  # 1 day 7 hours 37 minutes
  # 1 day 20 hours 35 minutes
  # 2 days 9 hours 33 minutes
  # 2 days 22 hours 30 minutes
  # 3 days 11 hours 28 minutes
  # 4 days 0 hours 26 minutes
  # 4 days 13 hours 23 minutes
  # 5 days 2 hours 21 minutes
  # 5 days 15 hours 19 minutes
  # 6 days 4 hours 17 minutes
  # 6 days 17 hours 14 minutes
  # 7 days 6 hours 12 minutes
  retry_on StandardError, attempts: 18,
                          wait: ->(attempts) { ([attempts, 6].min**6) + 5 }

  around_perform do |job, actual_job_code|
    PaperTrail.request(whodunnit: "Background job: #{job.class.name}") do
      actual_job_code.call
    end
  end
end
