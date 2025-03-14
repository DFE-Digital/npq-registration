RSpec.shared_examples "a mailer with redacted logs" do
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

  it "redacts the processing log entry" do
    line = log.lines.find { _1.include? "processed outbound mail" }

    expect(line).to be_present
    expect(line).not_to include(to)
    expect(line).to include("[FILTERED]")
  end

  it "redacts the delivery log entry" do
    line = log.lines.find { _1.include? "Delivered mail" }

    expect(line).to be_present
    expect(line).not_to include(to)
    expect(line).to include("[FILTERED]")
  end
end
