class ApplicationMailer < Mail::Notify::Mailer
  default from: "continuing-professional-development@digital.education.gov.uk"
  layout "mailer"
end
