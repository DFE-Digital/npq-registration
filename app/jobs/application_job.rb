class ApplicationJob < ActiveJob::Base
  rescue_from(StandardError) do |exception|
    Sentry.capture_exception(exception)

    raise exception
  end
end
