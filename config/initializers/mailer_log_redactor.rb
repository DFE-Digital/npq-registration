module MailerLogRedactor
  def initialize(event:, log_duration: false)
    event.payload = redact(event.payload)
    super(event:, log_duration:)
  end

private

  def redact(payload)
    @filter ||= ActiveSupport::ParameterFilter.new(filter_parameters)
    @filter.filter(payload)
  end

  def filter_parameters
    Rails.application.config.filter_parameters
  end
end

RailsSemanticLogger::ActionMailer::LogSubscriber::EventFormatter.prepend(MailerLogRedactor)
