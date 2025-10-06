class ApplicationJob < ActiveJob::Base
  rescue_from(StandardError) do |exception|
    Sentry.capture_exception(exception)

    raise exception
  end

  around_perform do |job, actual_job_code|
    PaperTrail.request(whodunnit: "Background Job #{job.class}") do
      actual_job_code.call
    end
  end
end
