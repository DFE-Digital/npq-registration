module QuestionTypes
  class TextField < Base
    # TODO: Move this onto Base?
    def default_styles
      {
        width: "full",
        label: header.present? ? {} : { size: "xl", tag: "h1" },
      }
    end

    # TODO: Would be great to use same translation patterns for all the questions to configure govuk components
    def title_locale_type
      :title
    end
  end
end
