require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  let(:mailer) do
    Class.new(ApplicationMailer) do
      def test(to:)
        template_mail("template_id", to:)
      end
    end
  end

  describe "redaction" do
    let(:to)   { "to@example.org" }
    let(:mail) { mailer.test(to:) }
    let(:io)   { StringIO.new }
    let(:log)  { io.tap(&:rewind).read }

    it "sends the email to the unredacted recipient" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries.last.to).to eq([to])
    end

    it "redacts the email address in logs" do
      SemanticLogger.add_appender(io:, level: :info)
      SemanticLogger.sync!

      mail.deliver_now

      [
        "processed outbound mail",
        "Delivered mail",
      ].each do |infix|
        line = log.lines.find { _1.include? infix }
        expect(line).not_to include(to)
        expect(line).to include("[REDACTED]")
      end
    end
  end
end
