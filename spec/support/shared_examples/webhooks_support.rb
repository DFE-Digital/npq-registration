# frozen_string_literal: true

RSpec.shared_examples "it locks whilst processing the webhook" do
  it "with an advisory lock" do
    allow(User).to receive(:with_advisory_lock!).and_call_original

    subject

    expect(User).to have_received(:with_advisory_lock!)
      .with(TeachingRecordSystem::Webhooks::Base::ADVISORY_LOCK,
            blocking: true,
            transaction: true)
  end
end
