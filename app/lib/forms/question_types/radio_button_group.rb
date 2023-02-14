module Forms
  module QuestionTypes
    class RadioButtonGroup < Base
      def title_locale_type
        :legend
      end

      def fieldset_legend_attributes
        return {} if @opts.empty?

        @opts.dig(:fieldset, :legend)
      end
    end
  end
end
