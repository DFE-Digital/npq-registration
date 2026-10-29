class ApplicationMailer < Mail::Notify::Mailer
  default from: "continuing-professional-development@digital.education.gov.uk"
  layout "mailer"

  ActionMailer::MailDeliveryJob.rescue_from(Exception) do |exception|
    Sentry.capture_exception(exception)

    raise exception
  end
end
