RSpec.shared_examples "a mailer with redacted logs" do
  before { delivery_events }

  let :delivery_events do
    capture_semantic_logger_events do
      mail.deliver_now
    end
  end

  it "sends the email to the unredacted recipient" do
    expect(ActionMailer::Base.deliveries.last.to).to eq([to])
  end

  it "redacts the processing log entry" do
    line = delivery_events.find { _1.message.include? "processed outbound mail" }.to_h.to_json

    expect(line).to be_present
    expect(line).not_to include(to)
    expect(line).to include("[FILTERED]")
  end

  it "redacts the delivery log entry" do
    line = delivery_events.find { _1.message.include? "Delivered mail" }.to_h.to_json

    expect(line).to be_present
    expect(line).not_to include(to)
    expect(line).to include("[FILTERED]")
  end
end
