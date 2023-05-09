module Forms
  module QuestionTypes
    class CheckBox < Base
      DEFAULT_STYLES = {
        legend: {
          size: "xl",
          tag: "h1",
        }.freeze,
      }.freeze

      attr_reader :checked_value, :unchecked_value, :required, :body

      def initialize(*args, checked_value: "1", unchecked_value: "0", required: false, body: nil, **opts)
        @checked_value = checked_value
        @unchecked_value = unchecked_value
        @required = required
        @body = Array.wrap(body)

        super(*args, **opts)
      end

      def title_locale_type
        :legend
      end

      def style_options
        DEFAULT_STYLES.deep_merge(@style_options)
      end
    end
  end
end
