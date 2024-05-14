module API
  module Errors
    class Response
      attr_reader :error, :params

      def initialize(error:, params:)
        @params = params
        @error = error
      end

      def call
        params.map do |param|
          {
            title: error,
            detail: param,
          }
        end
      rescue StandardError
        [{
          title: error,
          detail: params,
        }]
      end

      def self.from(service)
        {
          errors: service
            .errors
            .messages
            .map { |title, detail| { title:, detail: detail.uniq.join(", ") } },
        }
      end
    end
  end
end
