require 'rouge/plugins/redcarpet'

module TemplateHandlers
  class HTMLWithCodeHighlighting < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end

  class Markdown
    def self.call(template, source)
      new.call(template, source)
    end

    def call(template, source)
      markdown = Redcarpet::Markdown.new(HTMLWithCodeHighlighting, fenced_code_blocks: true)
      markdown.render(source.to_s).inspect.html_safe
    end
  end
end
