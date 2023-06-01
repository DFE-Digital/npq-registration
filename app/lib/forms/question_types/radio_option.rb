module Forms
  module QuestionTypes
    RadioOption = Struct.new(:value, :link_errors, :divider, :revealed_question, :label, :hint, keyword_init: true)

    class RadioOption
      def to_options
        {
          link_errors:,
          label: normalize_text_for(label),
          hint: normalize_text_for(hint),
        }.compact
      end

    private

      def normalize_text_for(value)
        return value.presence if value.blank? || value.is_a?(Hash)

        { text: value }
      end
    end
  end
end
