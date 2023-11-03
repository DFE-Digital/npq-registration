module QuestionTypes
  class RadioButtonGroup < Base
    DEFAULT_STYLES = {
      legend: {
        size: "xl",
        tag: "h1",
      }.freeze,
    }.freeze

    def title_locale_type
      :legend
    end

    def fieldset_styles
      DEFAULT_STYLES.deep_merge(style_options)
    end
  end
end
