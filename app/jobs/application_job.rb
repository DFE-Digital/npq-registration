class ApplicationJob < ActiveJob::Base
  rescue_from(StandardError) do |exception|
    Sentry.capture_exception(exception)

    raise exception
  end

  around_perform do |job, actual_job_code|
    PaperTrail.request(whodunnit: job.class.to_s) do
      actual_job_code.call
    end
  end
end
