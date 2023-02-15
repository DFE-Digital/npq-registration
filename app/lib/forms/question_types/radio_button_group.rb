module Forms
  module QuestionTypes
    class RadioButtonGroup < Base
      def title_locale_type
        :legend
      end

      def fieldset_legend_attributes
        return {} if @style_options.empty?

        @style_options.dig(:fieldset, :legend)
      end
    end
  end
end
