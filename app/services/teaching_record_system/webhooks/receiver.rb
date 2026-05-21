module TeachingRecordSystem
  module Webhooks
    class Receiver
      def self.call(webhook_params:)
        new(webhook_params:).call
      end

      def initialize(webhook_params:)
        self.webhook_params = webhook_params
      end

    private

      attr_accessor :webhook_params

    end
  end
end
