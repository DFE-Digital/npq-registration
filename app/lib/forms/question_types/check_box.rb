module Forms
  module QuestionTypes
    class CheckBox < Base
      attribute :checked_value, default: "1".freeze
      attribute :unchecked_value, default: "0".freeze
      attribute :required, default: false

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
