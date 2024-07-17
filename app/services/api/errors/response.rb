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
            .map { |error, detail| new(error:, params: detail.uniq).call }.flatten,
        }
      end
    end
  end
end
