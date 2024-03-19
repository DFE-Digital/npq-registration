module TemplateHandlers
  class Markdown
    def self.call(_template, source)
      GovukMarkdown.render(source).inspect.html_safe
    end
  end
end

ActionView::Template.register_template_handler :md, TemplateHandlers::Markdown
ActionView::Template.register_template_handler :markdown, TemplateHandlers::Markdown
