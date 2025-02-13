RSpec.shared_examples "a mailer with redacted logs" do
  # let(:to)   { "to@example.org" }
  # let(:mail) { mailer.test(to:) }
  let(:io)  { StringIO.new }
  let(:log) { io.tap(&:rewind).read }

  before do
    SemanticLogger.add_appender(io:, level: :info)
    SemanticLogger.sync!

    mail.deliver_now
  end

  it "sends the email to the unredacted recipient" do
    expect(ActionMailer::Base.deliveries.last.to).to eq([to])
  end

  it "redacts the email address in the processing log" do
    line = log.lines.find { _1.include? "processed outbound mail" }

    expect(line).to be_present
    expect(line).not_to include(to)
    expect(line).to include("[REDACTED]")
  end

  it "redacts the email address in the delivery log" do
    line = log.lines.find { _1.include? "Delivered mail" }

    expect(line).to be_present
    expect(line).not_to include(to)
    expect(line).to include("[REDACTED]")
  end
end
