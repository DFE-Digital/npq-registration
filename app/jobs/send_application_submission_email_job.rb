class SendApplicationSubmissionEmailJob < ApplicationJob
  include CourseHelper

  queue_as :default

  def perform(application:, email_template:)
    ApplicationSubmissionMailer.application_submitted_mail(
      email_template,
      to: application.user.email,
      full_name: application.user.full_name,
      provider_name: application.lead_provider.name,
      course_name: localise_sentence_embedded_course_name(application.course),
      amount: application.raw_application_data["funding_amount"],
      ecf_id: application.ecf_id,
    ).deliver_now
  end
end
