require "rouge/plugins/redcarpet"

module TemplateHandlers
  class HTMLWithCodeHighlighting < GovukMarkdown::Renderer
    include Rouge::Plugins::Redcarpet

    def initialize(govuk_options = {})
      super(govuk_options, { with_toc_data: true, link_attributes: { class: "govuk-link" } })
    end
  end

  class Markdown
    def self.call(template, source)
      new.call(template, source)
    end

    def call(_template, source)
      markdown = Redcarpet::Markdown.new(HTMLWithCodeHighlighting, fenced_code_blocks: true)
      markdown.render(source.to_s).inspect.html_safe
    end
  end
end

ActionView::Template.register_template_handler :md, TemplateHandlers::Markdown
ActionView::Template.register_template_handler :markdown, TemplateHandlers::Markdown
