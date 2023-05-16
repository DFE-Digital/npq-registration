module Forms
  module QuestionTypes
    class CheckBox < Base
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

      def default_styles
        {
          legend: {
            size: "xl",
            tag: "h1",
          },
          hint: nil,
        }
      end
    end
  end
end
