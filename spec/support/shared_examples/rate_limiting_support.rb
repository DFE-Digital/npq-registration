# frozen_string_literal: true

RSpec.shared_examples "a rate limited endpoint", :rack_attack do |desc|
  describe desc do
    let(:limit) { 2 }
    let(:throttle) { Rack::Attack.throttles[desc] }

    subject { response }

    before do
      memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
      allow(Rack::Attack.cache).to receive(:store) { memory_store }

      allow(throttle).to receive(:limit) { limit }

      allow(Rails.logger).to receive(:warn)

      freeze_time

      request_count.times { perform_request }
    end

    context "when fewer than rate limit" do
      let(:request_count) { limit - 1 }

      it { is_expected.to have_http_status(:success) }
    end

    context "when more than rate limit" do
      let(:request_count) { limit + 1 }

      it { is_expected.to have_http_status(:too_many_requests) }

      it "logs a warning" do
        expect(Rails.logger).to have_received(:warn).with(
          %r{\[rack-attack\] Throttled request [a-zA-Z0-9]{20} from #{Regexp.escape(request.remote_ip)} to '#{request.path}'},
        )
      end

      it "allows another request when the time restriction has passed" do
        travel(throttle.period + 10.seconds)
        perform_request
        expect(subject).to have_http_status(:success)
      end

      it "allows another request if the condition changes" do
        change_condition
        perform_request
        expect(subject).to have_http_status(:success)
      end
    end
  end
end
