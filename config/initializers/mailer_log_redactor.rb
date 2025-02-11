module MailerLogRedactor
  def initialize(event:, log_duration: false)
    super(event: redact_event(event), log_duration:)
  end

private

  REDACTOR = proc { _1[:to] = "[REDACTED]" if _1.try(:[], :to).present? }

  def redact_event(event)
    event.payload.yield_self(&REDACTOR)
    event.payload[:args].try(:each, &REDACTOR)

    event
  end
end

RailsSemanticLogger::ActionMailer::LogSubscriber::EventFormatter.prepend(MailerLogRedactor)
